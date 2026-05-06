import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    let trialStatusText: String?
    let onImageDropped: (URL) -> Void
    let onShowHistory: () -> Void
    @State private var isDragOver = false
    @State private var isLoadingDrop = false
    @State private var openPanel: NSOpenPanel?

    private var isScreenshotMode: Bool {
        ProcessInfo.processInfo.environment["SHEETSNAP_SCREENSHOT_MODE"] != nil
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Label {
                    Text("SheetSnap")
                } icon: {
                    Image(systemName: "tablecells")
                        .foregroundStyle(Color.accentColor)
                }
                .font(.headline)
                Spacer()
                Button("History", action: onShowHistory)
                    .buttonStyle(BlueSolidButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)

            Spacer()

            VStack(spacing: 18) {
                ContentUnavailableView {
                    VStack(spacing: 10) {
                        Image(systemName: "tablecells.badge.ellipsis")
                            .font(.system(size: 42, weight: .medium))
                            .foregroundStyle(Color.accentColor)
                        Text("Import a Table Image")
                    }
                } description: {
                    Text("Choose an image or drop one here to extract rows and columns.")
                }

                GroupBox {
                    VStack(spacing: 3) {
                        if isLoadingDrop {
                            ProgressView()
                                .controlSize(.small)
                            Text("Importing image…")
                                .font(.callout.weight(.medium))
                        } else {
                            Text(isDragOver ? "Release to import" : "Drop image here")
                                .font(.callout.weight(.medium))
                            Text("PNG, JPG, HEIC, TIFF")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 110)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isDragOver ? Color.accentColor : Color.accentColor.opacity(0.28),
                            style: StrokeStyle(
                                lineWidth: isDragOver ? 2 : 1.5,
                                dash: isDragOver ? [] : [6, 3]
                            )
                        )
                }
                .onDrop(of: [.image, .fileURL], isTargeted: $isDragOver, perform: handleDrop)

                Button("Choose Image") { chooseFile() }
                    .buttonStyle(BlueSolidButtonStyle())

                if let trialStatusText {
                    Text(trialStatusText)
                        .font(.footnote.weight(.medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Text("Files stay on your Mac. The model may download on first import.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 420)
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.bottom, 20)
    }

    // MARK: - Drop handler

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        isDragOver = false
        isLoadingDrop = true
        dismissOpenPanelIfNeeded()

        let finishWithURL: (URL?) -> Void = { url in
            DispatchQueue.main.async {
                isLoadingDrop = false
                guard let url else { return }
                onImageDropped(url)
            }
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, _ in
                guard let url, let importedURL = importAccessibleCopy(of: url) else {
                    finishWithURL(nil)
                    return
                }
                finishWithURL(importedURL)
            }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                let sourceURL: URL?
                if let data = item as? Data {
                    sourceURL = URL(dataRepresentation: data, relativeTo: nil)
                } else if let url = item as? URL {
                    sourceURL = url
                } else {
                    sourceURL = nil
                }

                guard let sourceURL, let importedURL = importAccessibleCopy(of: sourceURL) else {
                    finishWithURL(nil)
                    return
                }
                finishWithURL(importedURL)
            }
        } else {
            isLoadingDrop = false
        }
        return true
    }

    // MARK: - Choose file

    func chooseFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image, .jpeg, .png, .heic, .tiff]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = "Extract Table"
        openPanel = panel
        panel.begin { response in
            let selectedURL = response == .OK ? panel.url : nil
            DispatchQueue.main.async {
                if openPanel === panel {
                    openPanel = nil
                }
                guard let selectedURL,
                      let importedURL = importAccessibleCopy(of: selectedURL) else {
                    return
                }
                onImageDropped(importedURL)
            }
        }
    }

    private func dismissOpenPanelIfNeeded() {
        guard let panel = openPanel else { return }
        openPanel = nil
        panel.cancel(nil)
        panel.orderOut(nil)
    }

    private func importAccessibleCopy(of sourceURL: URL) -> URL? {
        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let ext = sourceURL.pathExtension.isEmpty ? "png" : sourceURL.pathExtension
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(ext)

        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destination)
            return destination
        } catch {
            return nil
        }
    }
}

private struct BlueSolidButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Color.white.opacity(isEnabled ? 1 : 0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        Color(
                            red: 0.05,
                            green: 0.48,
                            blue: 0.98,
                            opacity: configuration.isPressed ? 0.82 : (isEnabled ? 1 : 0.65)
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
    }
}
