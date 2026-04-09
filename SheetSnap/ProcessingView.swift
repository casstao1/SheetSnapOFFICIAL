import SwiftUI

struct ProcessingView: View {
    let currentStep: String
    @State private var rotation = 0.0

    var body: some View {
        VStack(spacing: 24) {
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
                Text("Reading your table…")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Text(currentStep)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .animation(.easeInOut, value: currentStep)
            }

            Spacer()
        }
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}
