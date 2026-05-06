import SwiftUI

struct ProcessingView: View {
    let currentStep: String

    @State private var spinRotation: Double = 0

    var body: some View {
        VStack(spacing: 14) {
            Spacer()

            // Spinning ring with icon
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.15), lineWidth: 3)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: 0.78)
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(spinRotation))

                Image(systemName: "tablecells")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }

            // Title
            Text("Reading your table...")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)

            // Current step
            Text(currentStep)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                spinRotation = 360
            }
        }
    }
}
