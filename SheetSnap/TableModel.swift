import SwiftUI
import MLXVLM
import MLXLMCommon
import CoreImage
import Hub
import Tokenizers

// MARK: - TableModel

@MainActor
class TableModel: ObservableObject {
    @Published var state: AppState = .idle
    private var modelContainer: ModelContainer?
    private var modelLoadTask: Task<ModelContainer, Error>?
    private static var didRegisterDoclingProcessorAlias = false
    #if DEBUG
    private static let allowsRemoteModelFallback = true
    #else
    private static let allowsRemoteModelFallback = false
    #endif
    private static let remoteModelId = "docling-project/SmolDocling-256M-preview-mlx-bf16-docling-snap"
    private static let localModelFolderName = "SmolDocling-256M-preview-mlx-bf16-docling-snap"

    func preloadModel() {
        guard modelContainer == nil, modelLoadTask == nil else { return }

        Task {
            do {
                _ = try await loadModelIfNeeded()
                if case .downloading = state {
                    state = .idle
                }
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    func retryModelPreload() {
        state = .idle
        preloadModel()
    }

    /// Process a single image file.
    func process(url: URL, history: HistoryManager? = nil) {
        Task {
            do {
                state = .processing("Reading table…")

                if let tsv = try await extractTableWithVision(on: url) {
                    storeResult(tsv, for: url, history: history)
                    return
                }

                state = .processing("Loading Docling fallback…")
                let container = try await loadModelIfNeeded()
                state = .processing("Reading table with Docling…")

                let rawDocTags = try await runInference(on: url, using: container)
                let tsv = TableTSV.normalize(DocTagsParser.toTSV(rawDocTags))
                guard TableTSV.isLikelyTable(tsv) else { throw SheetSnapError.noText }

                storeResult(tsv, for: url, history: history)
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    private func extractTableWithVision(on url: URL) async throws -> String? {
        do {
            let rawTSV = try await Task.detached(priority: .userInitiated) {
                try VisionTableExtractor().extract(from: url)
            }.value
            let normalized = TableTSV.normalize(rawTSV)
            return TableTSV.isLikelyTable(normalized) ? normalized : nil
        } catch let error as SheetSnapError {
            switch error {
            case .imageLoad:
                throw error
            case .noText, .modelHostUnavailable, .modelAssetUnavailable:
                return nil
            }
        } catch {
            return nil
        }
    }

    private func storeResult(_ tsv: String, for url: URL, history: HistoryManager?) {
        let entry = HistoryEntry(
            id: UUID(),
            date: Date(),
            tsv: tsv,
            filename: url.deletingPathExtension().lastPathComponent
        )
        history?.add(entry)
        state = .result(tsv)
    }

    private func loadModelIfNeeded() async throws -> ModelContainer {
        if let existing = modelContainer { return existing }
        if let task = modelLoadTask { return try await task.value }

        Self.registerDoclingProcessorAliasIfNeeded()
        state = .downloading(0)

        let hub = try Self.modelHub()
        let config = try await Self.resolveModelConfiguration(
            using: hub,
            progressHandler: { [weak self] progress in
                Task { @MainActor in
                    guard let self else { return }
                    switch self.state {
                    case .idle, .downloading:
                        self.state = .downloading(progress)
                    default:
                        break
                    }
                }
            }
        )

        let task = Task<ModelContainer, Error> {
            let maxAttempts = 3
            var lastError: Error?

            for attempt in 1...maxAttempts {
                do {
                    return try await VLMModelFactory.shared.loadContainer(
                        hub: hub,
                        configuration: config
                    ) { [weak self] progress in
                        Task { @MainActor in
                            guard let self else { return }
                            switch self.state {
                            case .idle, .downloading:
                                self.state = .downloading(progress.fractionCompleted)
                            default:
                                break
                            }
                        }
                    }
                } catch {
                    lastError = error
                    guard Self.shouldRetryModelLoad(error), attempt < maxAttempts else {
                        break
                    }

                    let delaySeconds = UInt64(attempt * 2)
                    try await Task.sleep(nanoseconds: delaySeconds * 1_000_000_000)
                }
            }

            if let lastError, Self.isTransientModelHostFailure(lastError) {
                throw SheetSnapError.modelHostUnavailable
            }
            throw lastError ?? SheetSnapError.noText
        }

        modelLoadTask = task
        do {
            let container = try await task.value
            modelContainer = container
            modelLoadTask = nil
            return container
        } catch {
            modelLoadTask = nil
            throw error
        }
    }

    private static func registerDoclingProcessorAliasIfNeeded() {
        guard !didRegisterDoclingProcessorAlias else { return }

        let creator: @Sendable (URL, any Tokenizer) throws -> any UserInputProcessor = { url, tokenizer in
            let rawData = try Data(contentsOf: url)
            let configuration = try decodeSmolDoclingProcessorConfiguration(from: rawData)
            return SmolVLMProcessor(configuration, tokenizer: tokenizer)
        }

        VLMProcessorTypeRegistry.shared.registerProcessorType("smolDoclingProcessor", creator: creator)
        VLMProcessorTypeRegistry.shared.registerProcessorType("SmolDoclingProcessor", creator: creator)
        didRegisterDoclingProcessorAlias = true
    }

    private nonisolated static func decodeSmolDoclingProcessorConfiguration(from data: Data) throws
        -> SmolVLMProcessorConfiguration
    {
        do {
            return try JSONDecoder().decode(SmolVLMProcessorConfiguration.self, from: data)
        } catch {
            guard
                var json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                throw error
            }

            // Docling's processor config omits SmolVLM's video_sampling block.
            if json["video_sampling"] == nil {
                json["video_sampling"] = [
                    "fps": 1,
                    "max_frames": 20,
                ]
            }

            let normalizedData = try JSONSerialization.data(withJSONObject: json)
            return try JSONDecoder().decode(SmolVLMProcessorConfiguration.self, from: normalizedData)
        }
    }

    private static func resolveModelConfiguration(
        using hub: HubApi,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> ModelConfiguration {
        if let localConfiguration = localModelConfiguration(using: hub) {
            return localConfiguration
        }

        if let backgroundAssetConfiguration = await ModelAssetPackManager.localModelConfiguration() {
            return backgroundAssetConfiguration
        }

        if let backgroundAssetConfiguration = try await ModelAssetPackManager.ensureModelIsAvailable(
            onProgress: progressHandler
        ) {
            return backgroundAssetConfiguration
        }

        guard allowsRemoteModelFallback else {
            throw SheetSnapError.modelAssetUnavailable
        }

        return ModelConfiguration(id: remoteModelId)
    }

    private static func localModelConfiguration(using hub: HubApi) -> ModelConfiguration? {
        if let bundledDirectory = bundledModelDirectory() {
            return ModelConfiguration(directory: bundledDirectory)
        }

        if let appSupportDirectory = appSupportModelDirectory(using: hub) {
            return ModelConfiguration(directory: appSupportDirectory)
        }

        return nil
    }

    private static func bundledModelDirectory() -> URL? {
        let candidates: [URL?] = [
            Bundle.main.resourceURL?.appendingPathComponent("Models").appendingPathComponent(localModelFolderName),
            Bundle.main.resourceURL?.appendingPathComponent(localModelFolderName),
        ]

        return candidates
            .compactMap { $0 }
            .first(where: isUsableModelDirectory)
    }

    private static func modelHub() throws -> HubApi {
        let fileManager = FileManager.default
        guard let base = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return defaultHubApi
        }

        let hubBase = base
            .appendingPathComponent("SheetSnap", isDirectory: true)
            .appendingPathComponent("HuggingFace", isDirectory: true)
        try fileManager.createDirectory(at: hubBase, withIntermediateDirectories: true)

        return HubApi(downloadBase: hubBase, useBackgroundSession: false)
    }

    private static func appSupportModelDirectory(using hub: HubApi) -> URL? {
        guard let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return cachedModelDirectory(using: hub)
        }

        let candidates = [
            cachedModelDirectory(using: hub),
            base.appendingPathComponent("SheetSnap/Models").appendingPathComponent(localModelFolderName),
            base.appendingPathComponent(localModelFolderName),
        ]

        return candidates
            .compactMap { $0 }
            .first(where: isUsableModelDirectory)
    }

    private static func cachedModelDirectory(using hub: HubApi) -> URL {
        hub.localRepoLocation(Hub.Repo(id: remoteModelId))
    }

    private static func isUsableModelDirectory(_ url: URL) -> Bool {
        let requiredFiles = [
            "config.json",
            "preprocessor_config.json",
            "processor_config.json",
            "tokenizer.json",
        ]

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return false
        }

        return requiredFiles.allSatisfy { file in
            FileManager.default.fileExists(atPath: url.appendingPathComponent(file).path)
        }
    }

    private static func shouldRetryModelLoad(_ error: Error) -> Bool {
        let message = error.localizedDescription.lowercased()
        return message.contains("status code: 500")
            || message.contains("status code: 502")
            || message.contains("status code: 503")
            || message.contains("status code: 504")
    }

    private static func isTransientModelHostFailure(_ error: Error) -> Bool {
        let message = error.localizedDescription.lowercased()
        return message.contains("status code: 500")
            || message.contains("status code: 502")
            || message.contains("status code: 503")
            || message.contains("status code: 504")
    }

    private func runInference(
        on url: URL,
        using container: ModelContainer
    ) async throws -> String {
        guard let ciImage = CIImage(contentsOf: url) else {
            throw SheetSnapError.imageLoad
        }

        let userInput = UserInput(
            prompt: "Convert table to OTSL.",
            images: [.ciImage(ciImage)]
        )

        let maxNewTokens = 2048

        return try await container.perform { [userInput] context in
            let input = try await context.processor.prepare(input: userInput)
            var tokenCount = 0
            var collectedTokens: [Int] = []
            var decodedText = ""
            var detokenizer = NaiveStreamingDetokenizer(tokenizer: context.tokenizer)

            _ = try MLXLMCommon.generate(
                input: input,
                parameters: GenerateParameters(
                    maxTokens: maxNewTokens,
                    temperature: 0.0,
                    topP: 1.0,
                    repetitionPenalty: 1.1,
                    repetitionContextSize: 20
                ),
                context: context
            ) { token in
                collectedTokens.append(token)
                tokenCount += 1
                detokenizer.append(token: token)

                if let nextChunk = detokenizer.next() {
                    decodedText += nextChunk
                    if decodedText.contains("</doctag>") {
                        return .stop
                    }
                }

                if tokenCount % 50 == 0 {
                    Task { @MainActor in
                        self.state = .processing("Reading table… (\(tokenCount) tokens)")
                    }
                }

                if tokenCount >= maxNewTokens {
                    return .stop
                }
                return .more
            }

            if decodedText.isEmpty {
                return context.tokenizer.decode(tokens: collectedTokens)
            }
            return decodedText
        }
    }
}

// MARK: - DocTags / OTSL Parser

struct DocTagsParser {
    static func toTSV(_ docTags: String) -> String {
        let tables = extractOTSLBlocks(from: docTags)
        if tables.isEmpty {
            if docTags.lowercased().contains("<doctag>") {
                return ""
            }
            return fallbackClean(docTags)
        }
        return tables
            .map { parseOTSL($0) }
            .map { rows in
                rows.map { $0.joined(separator: "\t") }.joined(separator: "\n")
            }
            .joined(separator: "\n\n")
    }

    private static func extractOTSLBlocks(from text: String) -> [String] {
        var blocks: [String] = []
        var searchRange = text.startIndex..<text.endIndex

        while let openRange = text.range(of: "<otsl>", range: searchRange) {
            let contentStart = openRange.upperBound
            if let closeRange = text.range(of: "</otsl>", range: contentStart..<text.endIndex) {
                blocks.append(String(text[contentStart..<closeRange.lowerBound]))
                searchRange = closeRange.upperBound..<text.endIndex
            } else {
                blocks.append(String(text[contentStart...]))
                break
            }
        }

        return blocks
    }

    private static func parseOTSL(_ otsl: String) -> [[String]] {
        let cellTags = ["<fcel>", "<ecel>", "<lcel>", "<ucel>", "<xcel>", "<ched>", "<rhed>", "<srow>"]
        let rowEnd = "<nl/>"

        var rows: [[String]] = []
        var currentRow: [String] = []
        var remaining = otsl

        while !remaining.isEmpty {
            remaining = String(remaining.drop(while: { $0.isWhitespace }))
            guard !remaining.isEmpty else { break }

            if remaining.hasPrefix(rowEnd) {
                rows.append(currentRow)
                currentRow = []
                remaining = String(remaining.dropFirst(rowEnd.count))
                continue
            }

            var foundTag: String?
            for tag in cellTags where remaining.hasPrefix(tag) {
                foundTag = tag
                break
            }

            if let tag = foundTag {
                remaining = String(remaining.dropFirst(tag.count))

                let isFilled = tag == "<fcel>" || tag == "<ched>" || tag == "<rhed>" || tag == "<srow>"
                if isFilled {
                    let cellText = readUntilNextTag(remaining, cellTags: cellTags, rowEnd: rowEnd)
                    let cleaned = cellText
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "\t", with: " ")
                    currentRow.append(cleaned)
                    remaining = String(remaining.dropFirst(cellText.count))
                } else {
                    currentRow.append("")
                }
            } else if let nextAngle = remaining.dropFirst().firstIndex(of: "<") {
                remaining = String(remaining[nextAngle...])
            } else {
                break
            }
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    private static func readUntilNextTag(
        _ text: String,
        cellTags: [String],
        rowEnd: String
    ) -> String {
        let allTags = cellTags + [rowEnd, "</otsl>"]

        var earliest = text.endIndex
        for tag in allTags {
            if let range = text.range(of: tag), range.lowerBound < earliest {
                earliest = range.lowerBound
            }
        }

        return String(text[text.startIndex..<earliest])
    }

    private static func fallbackClean(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        if text.hasPrefix("```"), let newline = text.firstIndex(of: "\n") {
            text = String(text[text.index(after: newline)...])
        }
        if text.hasSuffix("```") {
            text = String(text.dropLast(3))
        }
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        let lines = text.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard !lines.isEmpty else { return "" }

        if lines.first?.contains("|") == true && lines.first?.contains("\t") != true {
            return lines
                .filter { line in
                    let stripped = line.replacingOccurrences(of: " ", with: "")
                    return !stripped.allSatisfy { "|-:".contains($0) }
                }
                .map { line in
                    line.split(separator: "|")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                        .joined(separator: "\t")
                }
                .joined(separator: "\n")
        }

        return lines.joined(separator: "\n")
    }
}

struct TableTSV {
    static func normalize(_ raw: String) -> String {
        let rows = parseRows(raw)
        guard !rows.isEmpty else { return "" }

        let trimmedRows = dropLeadingCaptionRows(from: rows)
        return trimmedRows
            .map { $0.joined(separator: "\t") }
            .joined(separator: "\n")
    }

    static func isLikelyTable(_ tsv: String) -> Bool {
        let rows = parseRows(tsv)
        guard rows.count >= 2 else { return false }

        let nonEmptyCounts = rows.map(nonEmptyCellCount).filter { $0 > 0 }
        guard let widestRow = nonEmptyCounts.max(), widestRow >= 2 else {
            return false
        }

        let structuredRows = nonEmptyCounts.filter { abs($0 - widestRow) <= 1 }.count
        return structuredRows >= 2
    }

    private static func parseRows(_ raw: String) -> [[String]] {
        raw
            .components(separatedBy: .newlines)
            .map { line in
                line
                    .split(separator: "\t", omittingEmptySubsequences: false)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            }
            .filter { row in
                !row.allSatisfy(\.isEmpty)
            }
    }

    private static func dropLeadingCaptionRows(from rows: [[String]]) -> [[String]] {
        let widestRow = rows.map(nonEmptyCellCount).max() ?? 0
        guard widestRow > 1 else { return rows }

        var firstTableRow = rows.startIndex
        while firstTableRow < rows.endIndex, nonEmptyCellCount(rows[firstTableRow]) <= 1 {
            firstTableRow += 1
        }

        guard firstTableRow < rows.endIndex else { return rows }
        return Array(rows[firstTableRow...])
    }

    private static func nonEmptyCellCount(_ row: [String]) -> Int {
        row.filter { !$0.isEmpty }.count
    }
}

// MARK: - XLSX Writer

struct XLSXWriter {
    /// Build a .xlsx file from tab-separated data and return the raw bytes.
    static func build(from tsv: String) -> Data {
        let rows = tsv.split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.split(separator: "\t", omittingEmptySubsequences: false).map(String.init) }

        var strings: [String] = []
        var stringIndex: [String: Int] = [:]
        for row in rows {
            for cell in row {
                if stringIndex[cell] == nil {
                    stringIndex[cell] = strings.count
                    strings.append(cell)
                }
            }
        }

        let sheetXML = buildSheetXML(rows: rows, stringIndex: stringIndex)
        let sharedXML = buildSharedStringsXML(strings)

        var zip = ZipWriter()
        zip.add("[Content_Types].xml", contentTypesXML)
        zip.add("_rels/.rels", relsXML)
        zip.add("xl/workbook.xml", workbookXML)
        zip.add("xl/_rels/workbook.xml.rels", workbookRelsXML)
        zip.add("xl/worksheets/sheet1.xml", sheetXML)
        zip.add("xl/sharedStrings.xml", sharedXML)
        zip.add("xl/styles.xml", stylesXML)
        return zip.finalize()
    }

    private static func buildSheetXML(rows: [[String]], stringIndex: [String: Int]) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
        <sheetData>
        """
        for (r, row) in rows.enumerated() {
            xml += "<row r=\"\(r + 1)\">"
            for (c, cell) in row.enumerated() {
                let col = columnLetter(c)
                let ref = "\(col)\(r + 1)"
                let idx = stringIndex[cell] ?? 0
                xml += "<c r=\"\(ref)\" t=\"s\"><v>\(idx)</v></c>"
            }
            xml += "</row>"
        }
        xml += "</sheetData></worksheet>"
        return xml
    }

    private static func buildSharedStringsXML(_ strings: [String]) -> String {
        let count = strings.count
        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="\(count)" uniqueCount="\(count)">
        """
        for s in strings {
            xml += "<si><t xml:space=\"preserve\">\(xmlEscape(s))</t></si>"
        }
        xml += "</sst>"
        return xml
    }

    private static func columnLetter(_ index: Int) -> String {
        var result = ""
        var n = index
        repeat {
            result = String(UnicodeScalar(65 + (n % 26))!) + result
            n = n / 26 - 1
        } while n >= 0
        return result
    }

    private static func xmlEscape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
         .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static let contentTypesXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
      <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
      <Default Extension="xml" ContentType="application/xml"/>
      <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
      <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
      <Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>
      <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
    </Types>
    """

    private static let relsXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
      <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
    </Relationships>
    """

    private static let workbookXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
      <sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets>
    </workbook>
    """

    private static let workbookRelsXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
      <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
      <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>
      <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
    </Relationships>
    """

    private static let stylesXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
      <fonts><font><sz val="11"/><name val="Calibri"/></font></fonts>
      <fills><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>
      <borders><border><left/><right/><top/><bottom/><diagonal/></border></borders>
      <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
      <cellXfs><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/></cellXfs>
    </styleSheet>
    """
}

// MARK: - Minimal ZIP Writer (STORE method, no compression)

struct ZipWriter {
    private var data = Data()
    private struct Entry { let name: String; let offset: UInt32; let size: UInt32; let crc: UInt32 }
    private var entries: [Entry] = []

    mutating func add(_ name: String, _ content: String) {
        guard let bytes = content.data(using: .utf8) else { return }
        addBytes(name, bytes)
    }

    mutating func addBytes(_ name: String, _ fileData: Data) {
        let offset = UInt32(data.count)
        let crc    = crc32(fileData)
        let size   = UInt32(fileData.count)
        let nameBytes = name.data(using: .utf8)!

        var h = Data()
        h += le32(0x04034b50); h += le16(20);   h += le16(0)
        h += le16(0);          h += le16(0);    h += le16(0)
        h += le32(crc);        h += le32(size); h += le32(size)
        h += le16(UInt16(nameBytes.count)); h += le16(0)
        h += nameBytes
        data += h
        data += fileData
        entries.append(Entry(name: name, offset: offset, size: size, crc: crc))
    }

    func finalize() -> Data {
        var out = data
        let cdStart = UInt32(out.count)
        for e in entries {
            let nb = e.name.data(using: .utf8)!
            var r = Data()
            r += le32(0x02014b50); r += le16(20); r += le16(20)
            r += le16(0); r += le16(0); r += le16(0); r += le16(0)
            r += le32(e.crc); r += le32(e.size); r += le32(e.size)
            r += le16(UInt16(nb.count)); r += le16(0); r += le16(0)
            r += le16(0); r += le16(0); r += le32(0); r += le32(e.offset)
            r += nb
            out += r
        }
        let cdSize = UInt32(out.count) - cdStart
        var eocd = Data()
        eocd += le32(0x06054b50); eocd += le16(0); eocd += le16(0)
        eocd += le16(UInt16(entries.count)); eocd += le16(UInt16(entries.count))
        eocd += le32(cdSize); eocd += le32(cdStart); eocd += le16(0)
        out += eocd
        return out
    }

    private func crc32(_ d: Data) -> UInt32 {
        var c: UInt32 = 0xFFFFFFFF
        for b in d {
            c ^= UInt32(b)
            for _ in 0..<8 { c = c & 1 != 0 ? (c >> 1) ^ 0xEDB88320 : c >> 1 }
        }
        return c ^ 0xFFFFFFFF
    }
    private func le16(_ v: UInt16) -> Data { Data([UInt8(v & 0xFF), UInt8(v >> 8)]) }
    private func le32(_ v: UInt32) -> Data {
        Data([UInt8(v & 0xFF), UInt8((v>>8)&0xFF), UInt8((v>>16)&0xFF), UInt8(v>>24)])
    }
}

// MARK: - Errors

enum SheetSnapError: LocalizedError {
    case imageLoad, noText, modelHostUnavailable, modelAssetUnavailable
    var errorDescription: String? {
        switch self {
        case .imageLoad: return "Could not load image"
        case .noText:    return "No table found in image"
        case .modelHostUnavailable:
            return "The model host is temporarily unavailable. Please try again in a minute."
        case .modelAssetUnavailable:
            return "The table model is not available on this Mac yet. Please try again after the app finishes downloading its Apple-hosted assets."
        }
    }
}
