import Vision
import CoreImage

/// Extracts a table from an image using Apple's Vision OCR.
/// Reads all text with bounding boxes, clusters into rows by Y-position,
/// detects column boundaries from gap patterns across rows, then assigns
/// each text fragment to the correct column — merging multi-word cells
/// like "South America" or "Highest in 24 hours" automatically.
struct VisionTableExtractor {

    struct TextItem {
        let text: String
        let minX: CGFloat   // normalized left edge
        let maxX: CGFloat   // normalized right edge
        let midX: CGFloat   // normalized 0–1, left → right
        let midY: CGFloat   // normalized 0–1, top → bottom (Y already flipped)
        let height: CGFloat // normalized block height
    }

    // MARK: - Public entry point

    /// Runs synchronously — call from a background Task.
    func extract(from url: URL) throws -> String {
        // Load image, respecting EXIF orientation
        guard let ciImage = CIImage(contentsOf: url) else {
            throw SheetSnapError.imageLoad
        }
        let orientation = exifOrientation(from: ciImage)

        let ctx = CIContext()
        guard let cgImage = ctx.createCGImage(ciImage, from: ciImage.extent) else {
            throw SheetSnapError.imageLoad
        }

        let items = try recognizeText(in: cgImage, orientation: orientation)
        guard !items.isEmpty else { throw SheetSnapError.noText }

        let rows = groupIntoRows(items)
        guard !rows.isEmpty else { throw SheetSnapError.noText }

        return rows.map { $0.joined(separator: "\t") }.joined(separator: "\n")
    }

    // MARK: - OCR

    private func recognizeText(in cgImage: CGImage,
                               orientation: CGImagePropertyOrientation) throws -> [TextItem] {
        var result: [TextItem] = []
        var thrownError: Error?

        let request = VNRecognizeTextRequest { req, error in
            if let error { thrownError = error; return }
            let obs = req.results as? [VNRecognizedTextObservation] ?? []
            result = obs.compactMap { o -> TextItem? in
                guard let top = o.topCandidates(1).first else { return nil }
                let text = top.string.trimmingCharacters(in: .whitespaces)
                guard !text.isEmpty else { return nil }
                // Vision origin is bottom-left; flip Y to top-left
                return TextItem(
                    text: text,
                    minX: o.boundingBox.minX,
                    maxX: o.boundingBox.maxX,
                    midX: o.boundingBox.midX,
                    midY: 1 - o.boundingBox.midY,
                    height: o.boundingBox.height
                )
            }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false   // keep table values verbatim

        let handler = VNImageRequestHandler(cgImage: cgImage,
                                            orientation: orientation,
                                            options: [:])
        try handler.perform([request])
        if let e = thrownError { throw e }
        return result
    }

    // MARK: - Row grouping

    private func groupIntoRows(_ items: [TextItem]) -> [[String]] {
        // Sort top-to-bottom
        let byY = items.sorted { $0.midY < $1.midY }

        // Adaptive threshold: ~55% of the median text-block height.
        let medianH = median(byY.map { $0.height })
        let threshold = max(medianH * 0.55, 0.008)

        var rowGroups: [[TextItem]] = []
        var current: [TextItem] = []
        var rowMidY = byY[0].midY

        for item in byY {
            if abs(item.midY - rowMidY) <= threshold {
                current.append(item)
                rowMidY = current.map { $0.midY }.reduce(0, +) / CGFloat(current.count)
            } else {
                if !current.isEmpty {
                    rowGroups.append(current.sorted { $0.midX < $1.midX })
                }
                current = [item]
                rowMidY = item.midY
            }
        }
        if !current.isEmpty {
            rowGroups.append(current.sorted { $0.midX < $1.midX })
        }

        // Detect column boundaries from gap patterns across all rows
        let boundaries = detectColumnBoundaries(rowGroups, medianHeight: medianH)

        if boundaries.isEmpty {
            // Fallback: simple merge with generous threshold
            return rowGroups.map { mergeRowItems($0, medianHeight: medianH) }
        }

        // Assign items to detected columns — items in the same column merge
        let numColumns = boundaries.count + 1
        return rowGroups.map { assignItemsToColumns($0, boundaries: boundaries, numColumns: numColumns) }
    }

    // MARK: - Column detection

    /// Finds column boundaries by looking at where inter-item gaps align
    /// across multiple rows.  A gap between "South" and "America" only
    /// appears in one row, but the gap between two actual columns shows
    /// up in nearly every data row — so it passes the support threshold.
    private func detectColumnBoundaries(_ rows: [[TextItem]],
                                        medianHeight: CGFloat) -> [CGFloat] {
        struct Gap {
            let mid: CGFloat
            let width: CGFloat
        }

        // Collect every inter-item gap from rows that have >1 item
        var allGaps: [Gap] = []
        for row in rows where row.count > 1 {
            for i in 0..<(row.count - 1) {
                let gapStart = row[i].maxX
                let gapEnd   = row[i + 1].minX
                if gapEnd > gapStart {
                    allGaps.append(Gap(mid: (gapStart + gapEnd) / 2,
                                       width: gapEnd - gapStart))
                }
            }
        }

        guard allGaps.count >= 2 else { return [] }

        // Sort by X position
        let sortedGaps = allGaps.sorted { $0.mid < $1.mid }

        // Cluster gaps at similar X positions
        let clusterRadius = medianHeight * 2.0
        var clusters: [[Gap]] = [[sortedGaps[0]]]

        for i in 1..<sortedGaps.count {
            let last = clusters[clusters.count - 1]
            let clusterAvgMid = last.map { $0.mid }.reduce(0, +) / CGFloat(last.count)
            if sortedGaps[i].mid - clusterAvgMid < clusterRadius {
                clusters[clusters.count - 1].append(sortedGaps[i])
            } else {
                clusters.append([sortedGaps[i]])
            }
        }

        // A cluster is a real column boundary only if enough rows "vote" for it
        let multiItemRowCount = rows.filter { $0.count > 1 }.count
        let minSupport = max(2, multiItemRowCount / 3)

        var boundaries: [CGFloat] = []
        for cluster in clusters where cluster.count >= minSupport {
            let avgMid = cluster.map { $0.mid }.reduce(0, +) / CGFloat(cluster.count)
            boundaries.append(avgMid)
        }

        return boundaries.sorted()
    }

    // MARK: - Column assignment

    /// Places each text item into its column slot based on the detected
    /// boundaries, then merges items sharing a slot into one string.
    private func assignItemsToColumns(_ items: [TextItem],
                                      boundaries: [CGFloat],
                                      numColumns: Int) -> [String] {
        guard !items.isEmpty else {
            return Array(repeating: "", count: numColumns)
        }

        // Column index: item falls between boundaries[i-1] and boundaries[i]
        func columnIndex(for midX: CGFloat) -> Int {
            for (i, boundary) in boundaries.enumerated() {
                if midX < boundary { return i }
            }
            return boundaries.count
        }

        // Group items by column
        var columnItems: [Int: [TextItem]] = [:]
        for item in items {
            let col = columnIndex(for: item.midX)
            columnItems[col, default: []].append(item)
        }

        // Build result with a consistent column count
        var result: [String] = []
        for col in 0..<numColumns {
            if let colItems = columnItems[col] {
                let sorted = colItems.sorted { $0.midX < $1.midX }
                result.append(sorted.map { $0.text }.joined(separator: " "))
            } else {
                result.append("")
            }
        }
        return result
    }

    // MARK: - Fallback merge (used when column detection finds nothing)

    private func mergeRowItems(_ items: [TextItem], medianHeight: CGFloat) -> [String] {
        guard !items.isEmpty else { return [] }

        let mergeThreshold = medianHeight * 0.6 * 3.5

        var cells: [String] = []
        var cellText = items[0].text
        var cellMaxX = items[0].maxX

        for i in 1..<items.count {
            let gap = items[i].minX - cellMaxX
            if gap < mergeThreshold {
                cellText += " " + items[i].text
                cellMaxX = items[i].maxX
            } else {
                cells.append(cellText)
                cellText = items[i].text
                cellMaxX = items[i].maxX
            }
        }
        cells.append(cellText)
        return cells
    }

    // MARK: - Helpers

    private func median(_ values: [CGFloat]) -> CGFloat {
        guard !values.isEmpty else { return 0.03 }
        let s = values.sorted()
        return s[s.count / 2]
    }

    private func exifOrientation(from ci: CIImage) -> CGImagePropertyOrientation {
        guard let raw = ci.properties[kCGImagePropertyOrientation as String] as? UInt32,
              let o = CGImagePropertyOrientation(rawValue: raw) else { return .up }
        return o
    }
}
