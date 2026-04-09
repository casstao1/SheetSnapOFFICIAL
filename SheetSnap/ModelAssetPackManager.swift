import Foundation
import MLXLMCommon

#if canImport(BackgroundAssets)
import BackgroundAssets
import System
#endif

enum ModelAssetPackManager {
    static let assetPackID = "smoldocling-model"
    static let appGroupID = "$(TeamIdentifierPrefix)group.com.SheetSnap.SheetSnap.backgroundassets"

    private static let localModelFolderName = "SmolDocling-256M-preview-mlx-bf16-docling-snap"
    private static let relativeModelDirectory = "Models/\(localModelFolderName)"
    private static let relativeConfigPath = "\(relativeModelDirectory)/config.json"

    static func localModelConfiguration() async -> ModelConfiguration? {
        guard #available(macOS 26.4, *) else { return nil }
        guard AssetPackManager.shared.assetPackIsAvailableLocally(withID: assetPackID) else {
            return nil
        }

        return try? modelConfiguration(using: AssetPackManager.shared)
    }

    static func ensureModelIsAvailable(
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> ModelConfiguration? {
        guard #available(macOS 26, *) else { return nil }
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

    @available(macOS 26, *)
    private static func assetPack(using manager: AssetPackManager) async throws -> AssetPack? {
        do {
            return try await manager.assetPack(withID: assetPackID)
        } catch let error as ManagedBackgroundAssetsError {
            switch error {
            case .assetPackNotFound(withID: _):
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
