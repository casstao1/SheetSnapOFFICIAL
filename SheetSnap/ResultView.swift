import SwiftUI

struct ResultView: View {
    let tsv: String
    let onReset: () -> Void
    @State private var copied = false

    var rows: [[String]] {
        tsv.split(separator: "\n", omittingEmptySubsequences: true)
            .filter { !$0.hasPrefix("#") }
            .map { line in
                line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
            }
    }

    var headers: [String] { rows.first ?? [] }
    var dataRows: [[String]] { rows.dropFirst().map { $0 } }

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
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
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)

                    Button(action: copyToClipboard) {
                        HStack(spacing: 5) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 11, weight: .medium))
                            Text(copied ? "Copied!" : "Copy to clipboard")
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

            Divider().opacity(0.5)

            // Table preview
            ScrollView([.horizontal, .vertical]) {
                VStack(spacing: 0) {
                    // Header row
                    if !headers.isEmpty {
                        HStack(spacing: 0) {
                            ForEach(Array(headers.enumerated()), id: \.offset) { _, header in
                                Text(header)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 9)
                                    .frame(minWidth: 90, alignment: .leading)
                                    .background(Color(NSColor.controlBackgroundColor).opacity(0.7))
                                Divider().frame(maxHeight: 32)
                            }
                        }
                        Divider()
                    }

                    // Data rows
                    ForEach(Array(dataRows.enumerated()), id: \.offset) { rowIdx, row in
                        HStack(spacing: 0) {
                            ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                                Text(cell)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .frame(minWidth: 90, alignment: .leading)
                                    .background(rowIdx % 2 == 0
                                                ? Color.clear
                                                : Color(NSColor.controlBackgroundColor).opacity(0.3))
                                Divider().frame(maxHeight: 28)
                            }
                        }
                        Divider().opacity(0.4)
                    }
                }
            }

            Divider().opacity(0.5)

            // Footer
            Text("Paste directly into Google Sheets or Excel · data is tab-separated")
                .font(.system(size: 10.5))
                .foregroundColor(.secondary.opacity(0.6))
                .padding(.vertical, 10)
        }
    }

    func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(tsv, forType: .tabularText)
        NSPasteboard.general.setString(tsv, forType: .string)
        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { copied = false }
        }
    }
}
