import SwiftUI

struct ErrorView: View {
    let message: String
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 34, weight: .ultraLight))
                    .foregroundColor(.red.opacity(0.8))
            }

            VStack(spacing: 8) {
                Text("Something went wrong")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Text(message)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: onReset) {
                Text("Try again")
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 9)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }
}
