import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    let onImageDropped: (URL) -> Void
    let onShowHistory: () -> Void
    @State private var isDragOver = false
    @State private var isHoveringButton = false
    @State private var isLoadingDrop = false

    var body: some View {
        VStack(spacing: 0) {
            // Title bar area
            HStack {
                HStack(spacing: 7) {
                    Image(systemName: "tablecells.badge.ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.accentColor)
                    Text("SheetSnap")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                Spacer()
                // History button
                Button(action: onShowHistory) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 11, weight: .medium))
                        Text("History")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                    .foregroundColor(.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))

            Divider().opacity(0.5)

            Spacer()

            // Hero icon
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.08))
                        .frame(width: 88, height: 88)
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 38, weight: .ultraLight))
                        .foregroundColor(.accentColor)
                }

                VStack(spacing: 5) {
                    Text("Photo to Spreadsheet")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("Drop a photo of any table — get instant\ncopy-paste data for Excel or Google Sheets")
                        .font(.system(size: 12.5))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }

            Spacer()

            // Drop zone
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isDragOver ? Color.accentColor : Color.secondary.opacity(0.25),
                        style: StrokeStyle(lineWidth: isDragOver ? 2 : 1.5, dash: [6, 4])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isDragOver
                                  ? Color.accentColor.opacity(0.05)
                                  : Color(NSColor.controlBackgroundColor).opacity(0.4))
                    )
                    .animation(.spring(response: 0.25), value: isDragOver)

                VStack(spacing: 9) {
                    if isLoadingDrop {
                        ProgressView()
                            .scaleEffect(0.9)
                            .frame(width: 28, height: 28)
                    } else {
                        Image(systemName: isDragOver ? "arrow.down.circle.fill" : "arrow.down.circle")
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(isDragOver ? .accentColor : .secondary)
                            .scaleEffect(isDragOver ? 1.12 : 1.0)
                            .animation(.spring(response: 0.25), value: isDragOver)
                    }

                    VStack(spacing: 3) {
                        Text(isLoadingDrop ? "Loading…" : (isDragOver ? "Release to extract" : "Drop image here"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(isDragOver || isLoadingDrop ? .accentColor : .primary)
                        if !isLoadingDrop {
                            Text("JPG · PNG · HEIC")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(height: 140)
            .padding(.horizontal, 36)
            .onDrop(of: [.image, .fileURL], isTargeted: $isDragOver, perform: handleDrop)

            // Or divider
            HStack(spacing: 10) {
                Rectangle().fill(Color.secondary.opacity(0.15)).frame(height: 0.5)
                Text("or").font(.system(size: 11)).foregroundColor(.secondary)
                Rectangle().fill(Color.secondary.opacity(0.15)).frame(height: 0.5)
            }
            .padding(.horizontal, 52)
            .padding(.vertical, 14)

            // Choose file button
            Button(action: chooseFile) {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                        .font(.system(size: 12, weight: .medium))
                    Text("Choose Image File")
                        .font(.system(size: 13, weight: .medium))
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 9)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .shadow(color: .accentColor.opacity(isHoveringButton ? 0.35 : 0.2),
                        radius: isHoveringButton ? 8 : 4, y: 2)
                .scaleEffect(isHoveringButton ? 1.02 : 1.0)
                .animation(.spring(response: 0.2), value: isHoveringButton)
            }
            .buttonStyle(.plain)
            .onHover { h in isHoveringButton = h }

            Spacer()

            Text("Runs on your Mac · first launch may download the AI model")
                .font(.system(size: 10.5))
                .foregroundColor(.secondary.opacity(0.55))
                .padding(.bottom, 18)
        }
        // Listen for Cmd+Shift+V paste notification
        .onReceive(NotificationCenter.default.publisher(for: .pasteImage)) { _ in
            handlePaste()
        }
    }

    // MARK: - Drop handler

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        isDragOver = false
        isLoadingDrop = true

        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    DispatchQueue.main.async {
                        isLoadingDrop = false
                        onImageDropped(url)
                    }
                } else {
                    DispatchQueue.main.async { isLoadingDrop = false }
                }
            }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.image.identifier) { item, _ in
                if let url = item as? URL {
                    DispatchQueue.main.async {
                        isLoadingDrop = false
                        onImageDropped(url)
                    }
                } else {
                    DispatchQueue.main.async { isLoadingDrop = false }
                }
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
        if panel.runModal() == .OK, let url = panel.url {
            onImageDropped(url)
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
}
