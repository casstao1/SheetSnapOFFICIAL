import SwiftUI
import AppKit

struct ResultView: View {
    let tsv: String
    let onReset: () -> Void
    let onSaved: (HistoryEntry) -> Void

    @State private var copied = false
    @State private var savedXLSX = false
    @State private var savedCSV = false
    @State private var exportErrorMessage: String?

    // Editable cell grid — initialized from tsv
    @State private var editableCells: [[String]] = []

    private var screenshotMode: String {
        ProcessInfo.processInfo.environment["SHEETSNAP_SCREENSHOT_MODE"] ?? ""
    }

    private var columnCount: Int {
        editableCells.map(\.count).max() ?? 0
    }

    /// Measure the widest text in each column using NSFont metrics.
    private var columnWidths: [CGFloat] {
        guard columnCount > 0 else { return [] }
        let regular = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let bold    = NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold)
        var widths  = Array(repeating: CGFloat(0), count: columnCount)

        for (i, h) in (editableCells.first ?? []).enumerated() where i < columnCount {
            let w = ceil((h as NSString).size(withAttributes: [.font: bold]).width)
            widths[i] = max(widths[i], w)
        }
        for row in editableCells.dropFirst() {
            for (i, cell) in row.enumerated() where i < columnCount {
                let w = ceil((cell as NSString).size(withAttributes: [.font: regular]).width)
                widths[i] = max(widths[i], w)
            }
        }
        return widths.map { max($0 + 40, 80) }
    }

    /// Reconstruct TSV from editable cells (used for copy/export).
    private var currentTSV: String {
        editableCells.map { $0.joined(separator: "\t") }.joined(separator: "\n")
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            Divider().opacity(0.5)

            if editableCells.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                let widths = columnWidths
                ScrollView([.horizontal, .vertical]) {
                    VStack(spacing: 0) {
                        // Header row
                        if let headerRow = editableCells.first {
                            HStack(spacing: 0) {
                                ForEach(Array(headerRow.enumerated()), id: \.offset) { i, _ in
                                    EditableCell(
                                        text: binding(row: 0, col: i),
                                        isHeader: true,
                                        width: i < widths.count ? widths[i] : 80,
                                        isLast: i == columnCount - 1,
                                        shouldFocusForScreenshot: false
                                    )
                                }
                            }
                        }

                        // Data rows
                        ForEach(Array(editableCells.dropFirst().enumerated()), id: \.offset) { rowIdx, row in
                            HStack(spacing: 0) {
                                ForEach(Array(row.enumerated()), id: \.offset) { i, _ in
                                    EditableCell(
                                        text: binding(row: rowIdx + 1, col: i),
                                        isHeader: false,
                                        width: i < widths.count ? widths[i] : 80,
                                        isLast: i == columnCount - 1,
                                        isAlternate: rowIdx % 2 != 0,
                                        shouldFocusForScreenshot: screenshotMode == "editing" && rowIdx == 1 && i == 2
                                    )
                                }
                            }
                        }
                    }
                }
            }

            Divider().opacity(0.5)

            Text("Click any cell to edit")
                .font(.system(size: 10.5))
                .foregroundColor(.secondary.opacity(0.6))
                .padding(.vertical, 10)
        }
        .onAppear { initCells() }
        .onChange(of: tsv) {
            initCells()
        }
        .alert("Couldn’t save file", isPresented: exportErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportErrorMessage ?? "The file couldn’t be saved.")
        }
    }

    // MARK: - Helpers

    private func binding(row: Int, col: Int) -> Binding<String> {
        Binding(
            get: {
                guard row < editableCells.count, col < editableCells[row].count else { return "" }
                return editableCells[row][col]
            },
            set: {
                guard row < editableCells.count, col < editableCells[row].count else { return }
                editableCells[row][col] = $0
            }
        )
    }

    private func initCells() {
        let parsed = tsv
            .split(separator: "\n", omittingEmptySubsequences: true)
            .filter { !$0.hasPrefix("#") }
            .map { line -> [String] in
                let cols = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
                return cols
            }
        guard !parsed.isEmpty else { editableCells = []; return }
        // Normalize all rows to same column count
        let maxCols = parsed.map(\.count).max() ?? 0
        editableCells = parsed.map { row in
            if row.count < maxCols { return row + Array(repeating: "", count: maxCols - row.count) }
            return row
        }
    }

    private var exportErrorBinding: Binding<Bool> {
        Binding(
            get: { exportErrorMessage != nil },
            set: { shouldShow in
                if !shouldShow {
                    exportErrorMessage = nil
                }
            }
        )
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 14))
                Text("Table extracted")
                    .font(.system(size: 13, weight: .semibold))
            }
            Spacer()
            HStack(spacing: 8) {
                Button(action: onReset) {
                    Text("New photo")
                        .font(.system(size: 12))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(NSColor.controlBackgroundColor))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .overlay(RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5))
                }
                .buttonStyle(.plain)

                // Save CSV
                Button(action: saveCSV) {
                    HStack(spacing: 4) {
                        Image(systemName: savedCSV ? "checkmark" : "arrow.down.doc")
                            .font(.system(size: 11, weight: .medium))
                        Text(savedCSV ? "Saved!" : "CSV")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .foregroundColor(savedCSV ? .green : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(RoundedRectangle(cornerRadius: 7)
                        .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5))
                    .animation(.easeInOut(duration: 0.2), value: savedCSV)
                }
                .buttonStyle(.plain)

                // Save XLSX
                Button(action: saveXLSX) {
                    HStack(spacing: 4) {
                        Image(systemName: savedXLSX ? "checkmark" : "arrow.down.doc.fill")
                            .font(.system(size: 11, weight: .medium))
                        Text(savedXLSX ? "Saved!" : "Excel")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .foregroundColor(savedXLSX ? .green : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(RoundedRectangle(cornerRadius: 7)
                        .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5))
                    .animation(.easeInOut(duration: 0.2), value: savedXLSX)
                }
                .buttonStyle(.plain)

                // Copy to clipboard
                Button(action: copyToClipboard) {
                    HStack(spacing: 5) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11, weight: .medium))
                        Text(copied ? "Copied!" : "Copy")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(copied ? Color.green : Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .animation(.easeInOut(duration: 0.2), value: copied)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Actions

    private func copyToClipboard() {
        let clipboardTSV = currentClipboardTSV
        let clipboardCSV = currentClipboardCSV
        let html = buildHTMLTable()
        let pasteboard = NSPasteboard.general
        let item = NSPasteboardItem()

        // Native macOS apps and many browsers fall back to plain text first.
        item.setString(clipboardTSV, forType: .string)
        item.setString(clipboardTSV, forType: .tabularText)
        item.setString(clipboardTSV, forType: NSPasteboard.PasteboardType("text/tab-separated-values"))
        if let utf8Text = clipboardTSV.data(using: .utf8) {
            item.setData(utf8Text, forType: .string)
            item.setData(utf8Text, forType: .tabularText)
            item.setData(utf8Text, forType: NSPasteboard.PasteboardType("public.utf8-plain-text"))
            item.setData(utf8Text, forType: NSPasteboard.PasteboardType("text/plain"))
            item.setData(utf8Text, forType: NSPasteboard.PasteboardType("text/tab-separated-values"))
        }

        // Some browsers prefer CSV over tabular text for external clipboard pastes.
        item.setString(clipboardCSV, forType: NSPasteboard.PasteboardType("text/csv"))
        if let utf8CSV = clipboardCSV.data(using: .utf8) {
            item.setData(utf8CSV, forType: NSPasteboard.PasteboardType("text/csv"))
        }

        // Browsers vary in which HTML clipboard flavor they inspect.
        item.setString(html, forType: .html)
        item.setString(html, forType: NSPasteboard.PasteboardType("text/html"))
        if let utf8HTML = html.data(using: .utf8) {
            item.setData(utf8HTML, forType: .html)
            item.setData(utf8HTML, forType: NSPasteboard.PasteboardType("text/html"))
        }

        pasteboard.clearContents()
        pasteboard.writeObjects([item])
        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { copied = false }
        }
    }

    private var currentClipboardTSV: String {
        editableCells
            .map { $0.joined(separator: "\t") }
            .joined(separator: "\r\n")
    }

    private var currentClipboardCSV: String {
        editableCells
            .map { row in
                row.map { cell in
                    let escaped = cell.replacingOccurrences(of: "\"", with: "\"\"")
                    return escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n")
                        ? "\"\(escaped)\""
                        : escaped
                }
                .joined(separator: ",")
            }
            .joined(separator: "\r\n")
    }

    private func buildHTMLTable() -> String {
        var html = """
        <html>
        <head><meta charset="utf-8"></head>
        <body><!--StartFragment--><table>
        """
        for (i, row) in editableCells.enumerated() {
            html += "<tr>"
            for cell in row {
                let tag = i == 0 ? "th" : "td"
                let escaped = cell
                    .replacingOccurrences(of: "&", with: "&amp;")
                    .replacingOccurrences(of: "<", with: "&lt;")
                    .replacingOccurrences(of: ">", with: "&gt;")
                    .replacingOccurrences(of: "\"", with: "&quot;")
                html += "<\(tag)>\(escaped)</\(tag)>"
            }
            html += "</tr>"
        }
        html += "</table><!--EndFragment--></body></html>"
        return html
    }

    private func saveCSV() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "table.csv"
        panel.prompt = "Save"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let csv = editableCells.map { row in
            row.map { cell in
                let escaped = cell.replacingOccurrences(of: "\"", with: "\"\"")
                return escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n")
                    ? "\"\(escaped)\""
                    : escaped
            }.joined(separator: ",")
        }.joined(separator: "\n")

        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            exportErrorMessage = nil
            markCSVSaved()
            onSaved(savedEntry(for: url))
        } catch {
            savedCSV = false
            exportErrorMessage = error.localizedDescription
            NSSound.beep()
        }
    }

    private func saveXLSX() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: "xlsx")!]
        panel.nameFieldStringValue = "table.xlsx"
        panel.prompt = "Save"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let data = XLSXWriter.build(from: currentTSV)
        do {
            try data.write(to: url)
            exportErrorMessage = nil
            markXLSXSaved()
            onSaved(savedEntry(for: url))
        } catch {
            savedXLSX = false
            exportErrorMessage = error.localizedDescription
            NSSound.beep()
        }
    }

    private func savedEntry(for url: URL) -> HistoryEntry {
        HistoryEntry(
            id: UUID(),
            date: Date(),
            tsv: currentTSV,
            filename: url.deletingPathExtension().lastPathComponent
        )
    }

    private func markCSVSaved() {
        withAnimation { savedCSV = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { savedCSV = false }
        }
    }

    private func markXLSXSaved() {
        withAnimation { savedXLSX = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { savedXLSX = false }
        }
    }
}

// MARK: - EditableCell

struct EditableCell: View {
    @Binding var text: String
    let isHeader: Bool
    let width: CGFloat
    let isLast: Bool
    var isAlternate: Bool = false
    var shouldFocusForScreenshot: Bool = false

    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("", text: $text)
            .font(.system(size: 12,
                          weight: isHeader ? .semibold : .regular,
                          design: .monospaced))
            .foregroundColor(isHeader ? .secondary : .primary)
            .textFieldStyle(.plain)
            .focused($isFocused)
            .frame(width: width, height: isHeader ? 34 : 30, alignment: .leading)
            .padding(.leading, 14)
            .background(
                isFocused
                    ? Color.accentColor.opacity(0.07)
                    : isHeader
                        ? Color(NSColor.controlBackgroundColor).opacity(0.7)
                        : isAlternate
                            ? Color(NSColor.controlBackgroundColor).opacity(0.25)
                            : Color.clear
            )
            .overlay(alignment: .trailing) {
                if !isLast {
                    Rectangle().fill(isFocused
                        ? Color.accentColor.opacity(0.3)
                        : Color(NSColor.separatorColor).opacity(isHeader ? 1.0 : 0.6))
                        .frame(width: 1)
                }
            }
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color(NSColor.separatorColor).opacity(isHeader ? 1.0 : 0.3))
                    .frame(height: isHeader ? 1 : 0.5)
            }
            .overlay(alignment: .top) {
                if isFocused {
                    Rectangle().fill(Color.accentColor.opacity(0.15)).frame(height: 1)
                }
            }
            .animation(.easeInOut(duration: 0.1), value: isFocused)
            .task {
                guard shouldFocusForScreenshot else { return }
                try? await Task.sleep(for: .milliseconds(200))
                isFocused = true
            }
    }
}
