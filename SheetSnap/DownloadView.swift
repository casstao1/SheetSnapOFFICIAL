import SwiftUI

struct DownloadView: View {
    let progress: Double

    private var steps: [DownloadStep] {
        [
            DownloadStep(
                id: "prepare-model",
                title: "Prepare Model",
                status: progress < 0.08 ? .active : .complete
            ),
            DownloadStep(
                id: "connect-source",
                title: "Connect Source",
                status: progress < 0.08 ? .pending : (progress < 0.2 ? .active : .complete)
            ),
            DownloadStep(
                id: "download-model",
                title: "Download Model",
                status: progress < 0.2 ? .pending : (progress < 0.9 ? .active : .complete)
            ),
            DownloadStep(
                id: "finalize-model",
                title: "Finalize Model",
                status: progress < 0.9 ? .pending : .active
            ),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 22) {
                DownloadHeroIcon()

                // Title + subtitle
                VStack(spacing: 5) {
                    Text("Downloading AI Model")
                        .font(.system(size: 19, weight: .bold))
                        .tracking(-0.3)
                        .multilineTextAlignment(.center)

                    Text("This only happens once on this Mac.")
                        .font(.system(size: 12.5))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .animation(nil, value: progress)

                // Step list
                VStack(spacing: 0) {
                    Divider()
                    ForEach(steps) { step in
                        DownloadStepRow(step: step)
                        Divider()
                    }
                }
                .frame(maxWidth: 300)

                // Footer
                Text("~500 MB · Estimated time: 2–4 min")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary.opacity(0.55))
                    .animation(nil, value: progress)
            }
            .padding(.horizontal, 48)

            Spacer()
        }
    }
}

private struct DownloadHeroIcon: View {
    @State private var rippleScale: CGFloat = 1.0
    @State private var rippleOpacity: Double = 0.35

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(rippleOpacity))
                .frame(width: 72, height: 72)
                .scaleEffect(rippleScale)
                .animation(.easeOut(duration: 1.8).repeatForever(autoreverses: false), value: rippleScale)
                .animation(.easeOut(duration: 1.8).repeatForever(autoreverses: false), value: rippleOpacity)

            Circle()
                .fill(Color.accentColor.opacity(0.12))
                .frame(width: 72, height: 72)

            Image(systemName: "arrow.down")
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(Color.accentColor)
        }
        .onAppear {
            rippleScale = 1.65
            rippleOpacity = 0
        }
    }
}

// MARK: - Step model

private struct DownloadStep: Identifiable {
    enum Status { case pending, active, complete }
    let id: String
    let title: String
    let status: Status
}

// MARK: - Step row

private struct DownloadStepRow: View {
    let step: DownloadStep

    var body: some View {
        HStack(spacing: 10) {
            dot
            Text(step.title)
                .font(.system(size: 13, weight: step.status == .pending ? .regular : .medium))
                .foregroundStyle(labelColor)
            Spacer(minLength: 0)
            if step.status == .complete {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 11)
        .animation(nil, value: step.status)
    }

    @ViewBuilder
    private var dot: some View {
        switch step.status {
        case .complete:
            Circle()
                .fill(Color.accentColor)
                .frame(width: 7, height: 7)
        case .active:
            Circle()
                .fill(Color.accentColor)
                .frame(width: 7, height: 7)
        case .pending:
            Circle()
                .fill(Color.secondary.opacity(0.22))
                .frame(width: 7, height: 7)
        }
    }

    private var labelColor: Color {
        switch step.status {
        case .complete: return .secondary
        case .active:   return .primary
        case .pending:  return Color.secondary.opacity(0.4)
        }
    }
}
