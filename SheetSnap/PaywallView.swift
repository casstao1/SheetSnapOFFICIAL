import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var trialManager: TrialManager

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.14))
                    .frame(width: 112, height: 112)

                Image(systemName: "creditcard.circle.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(spacing: 10) {
                Text("Trial Ended")
                    .font(.system(size: 34, weight: .semibold))

                Text(trialManager.paywallSubtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 560)
            }

            VStack(alignment: .leading, spacing: 12) {
                paywallBullet("Unlimited table imports after purchase")
                paywallBullet(secondBulletText)
                paywallBullet(thirdBulletText)
            }
            .padding(20)
            .frame(maxWidth: 520, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.04))
            )

            HStack(spacing: 12) {
                Button(trialManager.purchaseButtonTitle) {
                    trialManager.beginPrimaryPurchaseFlow()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(trialManager.isPurchaseInFlight)

                if trialManager.showsRestorePurchases {
                    Button("Restore Purchases") {
                        trialManager.restorePurchases()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(trialManager.isPurchaseInFlight)
                }
            }

            if let purchaseErrorMessage = trialManager.purchaseErrorMessage {
                Text(purchaseErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)
            }

            Text(trialManager.providerDetailText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 520)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }

    private var secondBulletText: String {
        "One-time Mac App Store unlock after the trial"
    }

    private var thirdBulletText: String {
        "Restore Purchases with your Apple account"
    }

    private func paywallBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.green)
            Text(text)
                .font(.body)
        }
    }
}
