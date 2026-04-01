import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    let onImageDropped: (URL) -> Void
    @State private var isDragOver = false
    @State private var isHoveringButton = false

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
                    Image(systemName: isDragOver ? "arrow.down.circle.fill" : "arrow.down.circle")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(isDragOver ? .accentColor : .secondary)
                        .scaleEffect(isDragOver ? 1.12 : 1.0)
                        .animation(.spring(response: 0.25), value: isDragOver)

                    VStack(spacing: 3) {
                        Text(isDragOver ? "Release to extract" : "Drop image here")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(isDragOver ? .accentColor : .primary)
                        Text("JPG · PNG · HEIC")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
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

            Text("Runs 100% on your Mac · no internet required after setup")
                .font(.system(size: 10.5))
                .foregroundColor(.secondary.opacity(0.55))
                .padding(.bottom, 18)
        }
    }

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    DispatchQueue.main.async { onImageDropped(url) }
                }
            }
        } else {
            provider.loadItem(forTypeIdentifier: UTType.image.identifier) { item, _ in
                if let url = item as? URL {
                    DispatchQueue.main.async { onImageDropped(url) }
                }
            }
        }
        return true
    }

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
}
