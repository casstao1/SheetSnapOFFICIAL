import SwiftUI

struct HistoryView: View {
    let onSelect: (HistoryEntry) -> Void
    let onDismiss: () -> Void
    @EnvironmentObject private var historyManager: HistoryManager

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 7) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.accentColor)
                    Text("Recent Extractions")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                Spacer()
                if !historyManager.entries.isEmpty {
                    Button("Clear All") { historyManager.clear() }
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .buttonStyle(.plain)
                }
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))

            Divider().opacity(0.5)

            if historyManager.entries.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "clock")
                        .font(.system(size: 32, weight: .ultraLight))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("No extractions yet")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(historyManager.entries) { entry in
                            HistoryRow(entry: entry, formatter: dateFormatter) {
                                onSelect(entry)
                            } onDelete: {
                                historyManager.remove(id: entry.id)
                            }
                            Divider().opacity(0.4).padding(.leading, 20)
                        }
                    }
                }
            }
        }
    }
}

struct HistoryRow: View {
    let entry: HistoryEntry
    let formatter: DateFormatter
    let onTap: () -> Void
    let onDelete: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "tablecells")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.accentColor.opacity(0.8))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.filename.isEmpty ? "Extracted Table" : entry.filename)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                Text("\(entry.rowCount) rows · \(entry.colCount) columns")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text(formatter.string(from: entry.date))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.7))
            }

            Spacer()

            if isHovering {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(isHovering
            ? Color(NSColor.controlBackgroundColor).opacity(0.6)
            : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .onHover { isHovering = $0 }
    }
}
