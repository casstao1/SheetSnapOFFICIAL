import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    let onImageDropped: (URL) -> Void
    let onShowHistory: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("didPromptForInitialFileAccess") private var didPromptForInitialFileAccess = false
    @State private var isDragOver = false
    @State private var isLoadingDrop = false
    @State private var openPanel: NSOpenPanel?
    @State private var didTriggerInitialPrompt = false

    private var isScreenshotMode: Bool {
        ProcessInfo.processInfo.environment["SHEETSNAP_SCREENSHOT_MODE"] != nil
    }

    private var heroIconColor: Color {
        colorScheme == .light ? Color.black.opacity(0.72) : Color.secondary
    }

    private var heroTitleColor: Color {
        colorScheme == .light ? Color.black.opacity(0.74) : .primary
    }

    private var heroDescriptionColor: Color {
        colorScheme == .light ? Color.black.opacity(0.64) : .secondary
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Label("SheetSnap", systemImage: "tablecells")
                    .font(.headline)
                Spacer()
                Button("History", action: onShowHistory)
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)

            Spacer()

            VStack(spacing: 18) {
                VStack(spacing: 12) {
                    Image(systemName: "tablecells.badge.ellipsis")
                        .font(.system(size: 46, weight: .medium))
                        .foregroundStyle(heroIconColor)

                    Text("Import a Table Image")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(heroTitleColor)

                    Text("Choose an image or drop one here to extract rows and columns.")
                        .font(.title3)
                        .foregroundStyle(heroDescriptionColor)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
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
                        .stroke(isDragOver ? Color.accentColor : Color.clear, lineWidth: 2)
                }
                .onDrop(of: [.image, .fileURL], isTargeted: $isDragOver, perform: handleDrop)

                HStack(spacing: 10) {
                    Button("Choose Image", action: chooseFile)
                        .buttonStyle(StableProminentButtonStyle())
                    Button("Paste Image", action: handlePaste)
                        .buttonStyle(.bordered)
                }

                Text("Files stay on your Mac.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 420)
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.bottom, 20)
        // Listen for Cmd+Shift+V paste notification
        .onReceive(NotificationCenter.default.publisher(for: .pasteImage)) { _ in
            handlePaste()
        }
        .task {
            requestInitialFileAccessIfNeeded()
        }
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

    // MARK: - Paste from clipboard

    func handlePaste() {
        let pb = NSPasteboard.general
        // Try to get image data from clipboard
        if let data = pb.data(forType: .tiff) ?? pb.data(forType: .png) {
            saveAndProcess(data: data, ext: "png")
        } else if let img = NSImage(pasteboard: pb) {
            // Convert NSImage to PNG data
            if let tiff = img.tiffRepresentation,
               let rep = NSBitmapImageRep(data: tiff),
               let png = rep.representation(using: .png, properties: [:]) {
                saveAndProcess(data: png, ext: "png")
            }
        }
    }

    private func saveAndProcess(data: Data, ext: String) {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(ext)
        do {
            try data.write(to: tmp)
            onImageDropped(tmp)
        } catch {
            // Silently fail — no URL to process
        }
    }

    private func dismissOpenPanelIfNeeded() {
        guard let panel = openPanel else { return }
        openPanel = nil
        panel.cancel(nil)
        panel.orderOut(nil)
    }

    private func requestInitialFileAccessIfNeeded() {
        guard !didTriggerInitialPrompt else { return }
        didTriggerInitialPrompt = true
        guard !isScreenshotMode else { return }
        guard !didPromptForInitialFileAccess else { return }
        didPromptForInitialFileAccess = true
        chooseFile()
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

private struct StableProminentButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white.opacity(isEnabled ? 1.0 : 0.75))
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor.opacity(isEnabled ? (configuration.isPressed ? 0.78 : 1.0) : 0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
            )
    }
}
