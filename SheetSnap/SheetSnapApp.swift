import SwiftUI

extension Notification.Name {
    static let pasteImage = Notification.Name("SheetSnap.pasteImage")
}

@main
struct SheetSnapApp: App {
    @StateObject private var historyManager = HistoryManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(historyManager)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .pasteboard) {
                Button("Paste Image") {
                    NotificationCenter.default.post(name: .pasteImage, object: nil)
                }
                .keyboardShortcut("v", modifiers: [.command, .shift])
            }
        }
    }
}
