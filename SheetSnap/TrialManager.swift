import Foundation
import AppKit
import StoreKit

@MainActor
final class TrialManager: ObservableObject {
    enum AccessState: Equatable {
        case trial(daysRemaining: Int)
        case expired
        case unlocked
    }

    struct Configuration {
        let trialLengthDays: Int
        let supportURL: URL?
        let appStoreUnlockProductID: String?

        static func fromBundle(_ bundle: Bundle = .main) -> Configuration {
            let trialLengthDays = Int(
                (bundle.object(forInfoDictionaryKey: "SheetSnapTrialLengthDays") as? String) ?? "7"
            ) ?? 7

            let appStoreUnlockProductID = (bundle.object(
                forInfoDictionaryKey: "SheetSnapAppStoreUnlockProductID"
            ) as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return Configuration(
                trialLengthDays: trialLengthDays,
                supportURL: bundle.url(forInfoDictionaryKey: "SheetSnapSupportURL"),
                appStoreUnlockProductID: appStoreUnlockProductID?.isEmpty == true ? nil : appStoreUnlockProductID
            )
        }
    }

    @Published private(set) var accessState: AccessState
    @Published private(set) var isResolvingAccessState = true
    @Published private(set) var isPurchaseInFlight = false
    @Published private(set) var purchaseErrorMessage: String?

    private let userDefaults: UserDefaults
    private let configuration: Configuration
    private let nowProvider: () -> Date
    private let calendar = Calendar.current

    private let trialStartKey = "appStoreTrialStartedAt"
    private let paidUnlockHintKey = "appStoreHasPaidUnlockHint"
    private var hasPaidUnlock = false
    private var appStoreProduct: Product?
    private var appStorePriceDisplay: String?
    private var transactionUpdatesTask: Task<Void, Never>?

    init(
        userDefaults: UserDefaults = .standard,
        configuration: Configuration = .fromBundle(),
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.userDefaults = userDefaults
        self.configuration = configuration
        self.nowProvider = nowProvider
        self.hasPaidUnlock = userDefaults.bool(forKey: paidUnlockHintKey)
        self.accessState = hasPaidUnlock
            ? .unlocked
            : .trial(daysRemaining: configuration.trialLengthDays)
        ensureTrialStartDate()
        transactionUpdatesTask = Task { [weak self] in
            await self?.observeTransactionUpdates()
        }

        Task { [weak self] in
            await self?.prepareForLaunch()
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    var requiresPurchase: Bool {
        if case .expired = accessState {
            return true
        }
        return false
    }

    var trialBannerText: String? {
        guard case .trial(let daysRemaining) = accessState else { return nil }
        let dayLabel = daysRemaining == 1 ? "day" : "days"
        return "\(configuration.trialLengthDays)-day free trial: \(daysRemaining) \(dayLabel) remaining."
    }

    var paywallSubtitle: String {
        "Your 7-day free trial has ended. Unlock SheetSnap with a one-time purchase on the Mac App Store."
    }

    var purchaseButtonTitle: String {
        if let appStorePriceDisplay {
            return "Unlock for \(appStorePriceDisplay)"
        }
        return "Unlock with Apple"
    }

    var providerDetailText: String {
        "Apple handles payment and restore through the Mac App Store."
    }

    var showsRestorePurchases: Bool {
        true
    }

    func refreshAccessState() {
        if hasPaidUnlock {
            accessState = .unlocked
            return
        }

        guard !isForcedExpired else {
            accessState = .expired
            return
        }

        let elapsedDays = elapsedTrialDays
        if elapsedDays >= configuration.trialLengthDays {
            accessState = .expired
        } else {
            accessState = .trial(daysRemaining: configuration.trialLengthDays - elapsedDays)
        }
    }

    func beginPrimaryPurchaseFlow() {
        purchaseErrorMessage = nil
        Task { await purchaseFromAppStore() }
    }

    func restorePurchases() {
        purchaseErrorMessage = nil
        Task { await syncAppStorePurchases() }
    }

    func openSupport() {
        open(configuration.supportURL)
    }

    #if DEBUG
    func resetTrialStateForDebug() {
        userDefaults.removeObject(forKey: trialStartKey)
        ensureTrialStartDate()
        refreshAccessState()
    }
    #endif

    private func prepareForLaunch() async {
        await refreshAppStoreUnlockStatus()
        await loadAppStoreProduct()
        await performLaunchGraceRecheckIfNeeded()
        isResolvingAccessState = false
    }

    private func performLaunchGraceRecheckIfNeeded() async {
        guard configuration.appStoreUnlockProductID != nil else { return }
        guard case .expired = accessState else { return }

        // Older installs may not have the local unlock hint yet even though StoreKit
        // will rehydrate a paid entitlement moments later. Hold the launch gate briefly
        // and recheck once so purchased users do not see a paywall flash.
        try? await Task.sleep(for: .milliseconds(750))
        await refreshAppStoreUnlockStatus()
    }

    private func observeTransactionUpdates() async {
        for await update in Transaction.updates {
            guard !Task.isCancelled else { break }

            switch update {
            case .verified(let transaction):
                await handleVerifiedTransaction(transaction)
            case .unverified(_, _):
                await MainActor.run {
                    purchaseErrorMessage = "The App Store could not verify this purchase."
                }
            }
        }
    }

    private func ensureTrialStartDate() {
        guard userDefaults.object(forKey: trialStartKey) == nil else { return }
        userDefaults.set(nowProvider(), forKey: trialStartKey)
    }

    private var elapsedTrialDays: Int {
        guard let startedAt = userDefaults.object(forKey: trialStartKey) as? Date else {
            return 0
        }

        let startOfTrial = calendar.startOfDay(for: startedAt)
        let startOfNow = calendar.startOfDay(for: nowProvider())
        return max(0, calendar.dateComponents([.day], from: startOfTrial, to: startOfNow).day ?? 0)
    }

    private var isForcedExpired: Bool {
        #if DEBUG
        ProcessInfo.processInfo.environment["SHEETSNAP_FORCE_TRIAL_EXPIRED"] == "1"
        #else
        false
        #endif
    }

    private func loadAppStoreProduct() async {
        guard let productID = configuration.appStoreUnlockProductID else { return }

        do {
            let products = try await Product.products(for: [productID])
            appStoreProduct = products.first
            appStorePriceDisplay = products.first?.displayPrice
        } catch {
            purchaseErrorMessage = "Unable to load the Mac App Store price right now."
        }
    }

    private func refreshAppStoreUnlockStatus() async {
        guard let productID = configuration.appStoreUnlockProductID else {
            setPaidUnlock(false)
            refreshAccessState()
            return
        }

        var unlocked = false
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else { continue }
            guard transaction.productID == productID else { continue }
            guard transaction.revocationDate == nil else { continue }
            unlocked = true
            break
        }

        setPaidUnlock(unlocked)
        refreshAccessState()
    }

    private func purchaseFromAppStore() async {
        guard let product = appStoreProduct else {
            purchaseErrorMessage = "The Mac App Store price is still loading. Try again in a moment."
            return
        }

        isPurchaseInFlight = true
        defer { isPurchaseInFlight = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await handleVerifiedTransaction(transaction)
                case .unverified(_, _):
                    purchaseErrorMessage = "The App Store could not verify this purchase."
                }
            case .pending:
                purchaseErrorMessage = "Your purchase is pending approval."
            case .userCancelled:
                break
            @unknown default:
                purchaseErrorMessage = "The App Store purchase did not complete."
            }
        } catch {
            purchaseErrorMessage = error.localizedDescription
        }
    }

    private func syncAppStorePurchases() async {
        isPurchaseInFlight = true
        defer { isPurchaseInFlight = false }

        do {
            try await AppStore.sync()
            await refreshAppStoreUnlockStatus()
        } catch {
            purchaseErrorMessage = "Restore Purchases failed. Please try again."
        }
    }

    private func handleVerifiedTransaction(_ transaction: Transaction) async {
        if transaction.productID == configuration.appStoreUnlockProductID,
           transaction.revocationDate == nil {
            setPaidUnlock(true)
            purchaseErrorMessage = nil
            refreshAccessState()
        }

        await transaction.finish()
    }

    private func setPaidUnlock(_ unlocked: Bool) {
        hasPaidUnlock = unlocked
        userDefaults.set(unlocked, forKey: paidUnlockHintKey)
    }

    private func open(_ url: URL?) {
        guard let url else { return }
        NSWorkspace.shared.open(url)
    }
}

private extension Bundle {
    func url(forInfoDictionaryKey key: String) -> URL? {
        guard let value = object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed) else {
            return nil
        }
        return url
    }
}
