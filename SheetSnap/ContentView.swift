import SwiftUI

enum AppState: Equatable {
    case idle
    case downloading(Double)
    case processing(String)
    case result(String)
    case error(String)
}

struct ContentView: View {
    @StateObject private var model = TableModel()

    var body: some View {
        ZStack {
            Color(NSColor.windowBackgroundColor).ignoresSafeArea()
            switch model.state {
            case .idle:
                DropZoneView { url in model.process(url: url) }
                    .transition(.opacity)
            case .downloading(let progress):
                DownloadView(progress: progress)
                    .transition(.opacity)
            case .processing(let step):
                ProcessingView(currentStep: step)
                    .transition(.opacity)
            case .result(let tsv):
                ResultView(tsv: tsv) { model.state = .idle }
                    .transition(.opacity)
            case .error(let msg):
                ErrorView(message: msg) { model.state = .idle }
                    .transition(.opacity)
            }
        }
        .frame(width: 520, height: 560)
        .animation(.easeInOut(duration: 0.25), value: model.state)
    }
}
