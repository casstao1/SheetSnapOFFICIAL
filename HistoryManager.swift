import SwiftUI

struct HistoryEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let tsv: String
    let filename: String

    // Derived display helpers
    var rowCount: Int { tsv.split(separator: "\n").count }
    var colCount: Int {
        tsv.split(separator: "\n").first
            .map { $0.split(separator: "\t", omittingEmptySubsequences: false).count } ?? 0
    }
    var preview: String {
        let rows = tsv.split(separator: "\n").prefix(2)
        return rows.map { String($0) }.joined(separator: " · ")
    }
}

class HistoryManager: ObservableObject {
    @Published private(set) var entries: [HistoryEntry] = []
    private let key = "sheetsnap.history"
    private let maxEntries = 30

    init() { load() }

    func add(_ entry: HistoryEntry) {
        entries.removeAll { $0.id == entry.id }
        entries.insert(entry, at: 0)
        if entries.count > maxEntries { entries = Array(entries.prefix(maxEntries)) }
        save()
    }

    func remove(id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func clear() {
        entries = []
        save()
    }

    func replaceEntries(_ newEntries: [HistoryEntry]) {
        entries = newEntries
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) else { return }
        entries = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
