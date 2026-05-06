import SwiftUI

struct LoadingChecklistStep: Identifiable {
    enum Status {
        case pending
        case active
        case complete
    }

    let id = UUID()
    let title: String
    let detail: String?
    let status: Status
}

struct LoadingChecklistView: View {
    let symbolName: String?
    let title: String?
    let subtitle: String?
    let footer: String?
    let steps: [LoadingChecklistStep]
    var color: Color = .green

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                if let symbolName {
                    Image(systemName: symbolName)
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(.secondary)
                }

                if let title {
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                        .multilineTextAlignment(.center)
                }

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    HStack(alignment: .top, spacing: 14) {
                        VStack(spacing: 0) {
                            stepIcon(for: step.status)
                                .frame(width: 22, height: 22)

                            if index < steps.count - 1 {
                                Rectangle()
                                    .fill(connectorColor(after: step.status))
                                    .frame(width: 2, height: 34)
                                    .padding(.top, 6)
                            }
                        }

                        Text(step.title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(stepTextColor(for: step.status))
                            .padding(.top, 1)

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                }
            }
            .frame(maxWidth: 420, alignment: .leading)
            .padding(.top, (symbolName != nil || title != nil || subtitle != nil) ? 34 : 0)

            if let footer {
                Text(footer)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 28)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 56)
        .padding(.vertical, 48)
        .frame(maxWidth: 620, alignment: .center)
    }

    @ViewBuilder
    private func stepIcon(for status: LoadingChecklistStep.Status) -> some View {
        switch status {
        case .complete:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(color)
        case .active:
            Circle()
                .fill(color)
                .overlay {
                    Circle()
                        .stroke(color.opacity(0.35), lineWidth: 6)
                }
        case .pending:
            Circle()
                .fill(Color.secondary.opacity(0.28))
                .frame(width: 12, height: 12)
        }
    }

    private func stepTextColor(for status: LoadingChecklistStep.Status) -> Color {
        switch status {
        case .complete:
            return color
        case .active:
            return color
        case .pending:
            return .secondary
        }
    }

    private func connectorColor(after status: LoadingChecklistStep.Status) -> Color {
        switch status {
        case .complete, .active:
            return color.opacity(0.9)
        case .pending:
            return .secondary.opacity(0.25)
        }
    }
}
