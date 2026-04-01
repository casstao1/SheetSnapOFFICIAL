import SwiftUI

struct DownloadView: View {
    let progress: Double

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: 88, height: 88)
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 38, weight: .ultraLight))
                    .foregroundColor(.accentColor)
            }

            VStack(spacing: 8) {
                Text("Downloading AI Model")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text("This only happens once. SheetSnap uses an on-device\nAI model — your data never leaves your Mac.")
                    .font(.system(size: 12.5))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 99)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 99)
                            .fill(Color.accentColor)
                            .frame(width: geo.size.width * progress, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 40)

                HStack {
                    Text(String(format: "%.0f%%", progress * 100))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.accentColor)
                    Spacer()
                    Text("~1.5 GB · one-time download")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 40)
            }

            Spacer()
        }
        .padding(32)
    }
}
