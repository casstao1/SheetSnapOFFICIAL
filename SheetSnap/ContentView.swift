import SwiftUI

enum AppState: Equatable {
    case idle
    case downloading(Double)
    case processing(String)
    case result(String)
    case history
    case error(String)
}

struct ContentView: View {
    @StateObject private var model = TableModel()
    @EnvironmentObject private var historyManager: HistoryManager

    var body: some View {
        ZStack {
            Color(NSColor.windowBackgroundColor).ignoresSafeArea()
            switch model.state {
            case .idle:
                DropZoneView(
                    onImageDropped: { url in
                        model.process(url: url, history: historyManager)
                    },
                    onShowHistory: { model.state = .history }
                )
                .transition(.opacity)

            case .downloading(let progress):
                DownloadView(progress: progress)
                    .transition(.opacity)

            case .processing(let step):
                ProcessingView(currentStep: step)
                    .transition(.opacity)

            case .result(let tsv):
                ResultView(tsv: tsv,
                           onReset: { model.state = .idle },
                           onSaved: { entry in historyManager.add(entry) })
                    .transition(.opacity)

            case .history:
                HistoryView(
                    onSelect: { entry in model.state = .result(entry.tsv) },
                    onDismiss: { model.state = .idle }
                )
                .transition(.opacity)

            case .error(let msg):
                ErrorView(message: msg) { model.retryModelPreload() }
                    .transition(.opacity)
            }
        }
        .frame(minWidth: 520, minHeight: 560)
        .animation(.easeInOut(duration: 0.25), value: model.state)
        .task {
            model.preloadModel()
        }
    }
}
