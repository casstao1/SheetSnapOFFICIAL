import SwiftUI
import StoreKit

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
    @Environment(\.requestReview) private var requestReview
    @AppStorage("successfulExtractionCount") private var successfulExtractionCount = 0
    @AppStorage("lastVersionPromptedForReview") private var lastVersionPromptedForReview = ""
    @State private var reviewPromptTask: Task<Void, Never>?

    private var screenshotScenario: ScreenshotScenario? {
        ScreenshotScenario(rawValue: ProcessInfo.processInfo.environment["SHEETSNAP_SCREENSHOT_MODE"] ?? "")
    }

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
            if configureScreenshotModeIfNeeded() {
                return
            }
            model.preloadModel()
        }
        .onChange(of: model.state) { oldState, newState in
            guard case .result = newState else { return }
            guard case .result = oldState else {
                successfulExtractionCount += 1
                scheduleReviewPromptIfNeeded()
                return
            }
        }
    }

    private func scheduleReviewPromptIfNeeded() {
        let currentVersion = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.0"

        guard successfulExtractionCount >= 3 else { return }
        guard lastVersionPromptedForReview != currentVersion else { return }

        lastVersionPromptedForReview = currentVersion
        reviewPromptTask?.cancel()
        reviewPromptTask = Task {
            try? await Task.sleep(for: .seconds(2))
            requestReview()
        }
    }

    @discardableResult
    private func configureScreenshotModeIfNeeded() -> Bool {
        guard let scenario = screenshotScenario else { return false }

        switch scenario {
        case .importScreen:
            model.state = .idle
        case .processingScreen:
            model.state = .processing("Reading table…")
        case .resultScreen:
            model.state = .result(ScreenshotScenario.sampleTSV)
        case .editingScreen:
            model.state = .result(ScreenshotScenario.sampleTSV)
        case .historyScreen:
            historyManager.replaceEntries(ScreenshotScenario.sampleHistory)
            model.state = .history
        }
        return true
    }
}

private enum ScreenshotScenario: String {
    case importScreen = "import"
    case processingScreen = "processing"
    case resultScreen = "result"
    case editingScreen = "editing"
    case historyScreen = "history"

    static let sampleTSV = """
    Speed (mph)\tDriver\tCar\tEngine\tDate
    407.447\tCraig Breedlove\tSpirit of America\tGE J47\t8/5/63
    526.277\tCraig Breedlove\tSpirit of America\tGE J79\t10/15/65
    600.601\tCraig Breedlove\tSpirit of America, Sonic 1\tGE J79\t11/15/65
    622.407\tGary Gabelich\tBlue Flame\tRocket\t10/23/70
    633.468\tRichard Noble\tThrust 2\tRR RG 146\t10/4/83
    """

    static let sampleHistory: [HistoryEntry] = [
        HistoryEntry(
            id: UUID(),
            date: Date().addingTimeInterval(-3600),
            tsv: sampleTSV,
            filename: "land-speed-records"
        ),
        HistoryEntry(
            id: UUID(),
            date: Date().addingTimeInterval(-86_400),
            tsv: """
            Product\tQ1\tQ2\tQ3
            MacBook Air\t120\t132\t148
            iPad Pro\t78\t84\t91
            Studio Display\t24\t27\t31
            """,
            filename: "quarterly-sales"
        ),
        HistoryEntry(
            id: UUID(),
            date: Date().addingTimeInterval(-172_800),
            tsv: """
            Name\tRole\tTeam
            Ava Chen\tDesigner\tProduct
            Noah Patel\tEngineer\tPlatform
            Mia Torres\tResearcher\tUX
            """,
            filename: "team-directory"
        ),
    ]
}
