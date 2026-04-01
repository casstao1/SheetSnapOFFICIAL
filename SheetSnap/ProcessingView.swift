import SwiftUI

struct ProcessingView: View {
    let currentStep: String
    @State private var rotation = 0.0

    let allSteps = [
        "Loading image",
        "Detecting table structure",
        "Extracting rows and columns",
        "Formatting output"
    ]

    var currentIndex: Int {
        allSteps.firstIndex(of: currentStep) ?? 0
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Spinner
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.12), lineWidth: 3)
                    .frame(width: 64, height: 64)
                Circle()
                    .trim(from: 0, to: 0.72)
                    .stroke(Color.accentColor,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(rotation))
                Image(systemName: "tablecells")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.accentColor.opacity(0.8))
            }

            VStack(spacing: 6) {
                Text("Reading your table...")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Text("Usually 15–30 seconds")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            // Step list
            VStack(spacing: 6) {
                ForEach(Array(allSteps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(stepColor(index).opacity(0.15))
                                .frame(width: 20, height: 20)
                            if index < currentIndex {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(stepColor(index))
                            } else if index == currentIndex {
                                Circle()
                                    .fill(stepColor(index))
                                    .frame(width: 7, height: 7)
                            } else {
                                Circle()
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(width: 7, height: 7)
                            }
                        }

                        Text(step)
                            .font(.system(size: 13, weight: index == currentIndex ? .medium : .regular))
                            .foregroundColor(index <= currentIndex ? .primary : .secondary.opacity(0.5))

                        Spacer()
                    }
                    .padding(.horizontal, 48)
                    .animation(.easeInOut, value: currentIndex)
                }
            }

            Spacer()
        }
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }

    func stepColor(_ index: Int) -> Color {
        if index < currentIndex { return .green }
        if index == currentIndex { return .accentColor }
        return .secondary
    }
}
