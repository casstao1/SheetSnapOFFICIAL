import SwiftUI

extension Notification.Name {
    static let resetModelCache = Notification.Name("SheetSnap.resetModelCache")
}

@main
struct SheetSnapApp: App {
    @StateObject private var historyManager = HistoryManager()
    @StateObject private var trialManager = TrialManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(historyManager)
                .environmentObject(trialManager)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        #if DEBUG
        .commands {
            CommandMenu("Debug") {
                Button("Reset Model Cache") {
                    NotificationCenter.default.post(name: .resetModelCache, object: nil)
                }
            }
        }
        #endif
    }
}
