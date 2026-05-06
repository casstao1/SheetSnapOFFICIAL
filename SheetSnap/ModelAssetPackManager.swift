import Foundation
import MLXLMCommon

#if canImport(BackgroundAssets)
import BackgroundAssets
import System
#endif

enum ModelAssetPackManager {
    static let assetPackID = "smoldocling-model"
    static let appGroupID =
        Bundle.main.object(forInfoDictionaryKey: "BAAppGroupID") as? String ??
        "group.com.SheetSnap.SheetSnap.backgroundassets"
    private static let distributionChannel =
        (Bundle.main.object(forInfoDictionaryKey: "SheetSnapDistributionChannel") as? String) ?? ""

    private static let localModelFolderName = "SmolDocling-256M-preview-mlx-bf16-docling-snap"
    private static let relativeModelDirectory = "Models/\(localModelFolderName)"
    private static let relativeConfigPath = "\(relativeModelDirectory)/config.json"
    #if DEBUG
    private static let logsMissingAssetPack = false
    #else
    private static let logsMissingAssetPack = true
    #endif

    private static var supportsBackgroundAssets: Bool {
        guard distributionChannel == "APP_STORE" else { return false }
        guard Bundle.main.object(forInfoDictionaryKey: "BAUsesAppleHosting") != nil else { return false }
        return true
    }

    static func localModelConfiguration() async -> ModelConfiguration? {
        guard supportsBackgroundAssets else { return nil }
        guard #available(macOS 26.4, *) else { return nil }
        guard AssetPackManager.shared.assetPackIsAvailableLocally(withID: assetPackID) else {
            return nil
        }

        return try? modelConfiguration(using: AssetPackManager.shared)
    }

    static func ensureModelIsAvailable(
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> ModelConfiguration? {
        guard supportsBackgroundAssets else { return nil }
        guard #available(macOS 26.4, *) else { return nil }
        let manager = AssetPackManager.shared
        guard let assetPack = try await assetPack(using: manager) else {
            return nil
        }

        let progressTask = Task {
            for await update in manager.statusUpdates(forAssetPackWithID: assetPack.id) {
                switch update {
                case .began:
                    onProgress(0)
                case .downloading(_, let progress):
                    onProgress(progress.fractionCompleted)
                case .finished:
                    onProgress(1)
                case .paused, .failed:
                    continue
                @unknown default:
                    continue
                }
            }
        }
        defer { progressTask.cancel() }

        try await manager.ensureLocalAvailability(of: assetPack)
        onProgress(1)
        return try modelConfiguration(using: manager)
    }

    static func removeLocalModelCache() async throws {
        guard supportsBackgroundAssets else { return }
        if #available(macOS 26.4, *) {
            try await AssetPackManager.shared.remove(assetPackWithID: assetPackID)
        }
    }

    @available(macOS 26, *)
    private static func assetPack(using manager: AssetPackManager) async throws -> AssetPack? {
        do {
            return try await manager.assetPack(withID: assetPackID)
        } catch let error as ManagedBackgroundAssetsError {
            switch error {
            case .assetPackNotFound(withID: _):
                if logsMissingAssetPack {
                    print("The asset pack with the ID \"\(assetPackID)\" couldn't be looked up.")
                }
                return nil
            case .fileNotFound(at: _):
                throw error
            @unknown default:
                throw error
            }
        }
    }

    @available(macOS 26, *)
    private static func modelConfiguration(using manager: AssetPackManager) throws -> ModelConfiguration {
        let configURL = try manager.url(for: FilePath(relativeConfigPath))
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            throw ManagedBackgroundAssetsError.fileNotFound(at: FilePath(relativeConfigPath))
        }

        return ModelConfiguration(directory: configURL.deletingLastPathComponent())
    }
}
