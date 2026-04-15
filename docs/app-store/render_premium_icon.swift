import AppKit
import Foundation

let sourceURL = URL(fileURLWithPath: "/Users/castao/Desktop/freepik_make-an-minimal-aesthetic_2785311228.png")
let repoRoot = URL(fileURLWithPath: "/Users/castao/Desktop/SheetSnap/SheetSnapOFFICIAL")
let outputDir = repoRoot.appendingPathComponent("docs/app-store/icon-premium", isDirectory: true)

struct PremiumVariant {
    let fileName: String
    let title: String
    let fillTop: NSColor
    let fillBottom: NSColor
    let overlay: NSColor
    let border: NSColor
    let shadowColor: NSColor
    let shadowBlur: CGFloat
    let shadowYOffset: CGFloat
}

let variants: [PremiumVariant] = [
    .init(
        fileName: "SheetSnapIcon-premium-teal.png",
        title: "Premium Teal",
        fillTop: NSColor(calibratedRed: 0.73, green: 0.90, blue: 0.85, alpha: 1.0),
        fillBottom: NSColor(calibratedRed: 0.42, green: 0.77, blue: 0.72, alpha: 1.0),
        overlay: NSColor(calibratedRed: 0.03, green: 0.16, blue: 0.19, alpha: 0.10),
        border: NSColor(calibratedRed: 0.12, green: 0.47, blue: 0.49, alpha: 0.26),
        shadowColor: NSColor(calibratedWhite: 0.0, alpha: 0.26),
        shadowBlur: 28,
        shadowYOffset: -10
    ),
    .init(
        fileName: "SheetSnapIcon-premium-deep.png",
        title: "Premium Deep",
        fillTop: NSColor(calibratedRed: 0.63, green: 0.86, blue: 0.82, alpha: 1.0),
        fillBottom: NSColor(calibratedRed: 0.28, green: 0.66, blue: 0.67, alpha: 1.0),
        overlay: NSColor(calibratedRed: 0.01, green: 0.11, blue: 0.14, alpha: 0.14),
        border: NSColor(calibratedRed: 0.08, green: 0.36, blue: 0.39, alpha: 0.32),
        shadowColor: NSColor(calibratedWhite: 0.0, alpha: 0.34),
        shadowBlur: 32,
        shadowYOffset: -12
    )
]

func loadImage(_ url: URL) -> NSImage {
    guard let image = NSImage(contentsOf: url) else {
        fatalError("Could not load source image")
    }
    return image
}

func pngRep(_ image: NSImage) -> NSBitmapImageRep {
    let data = image.tiffRepresentation!
    return NSBitmapImageRep(data: data)!
}

func extractSourceTile(_ image: NSImage) -> NSImage {
    let inset: CGFloat = 76
    let cropRect = NSRect(
        x: inset,
        y: inset,
        width: image.size.width - inset * 2,
        height: image.size.height - inset * 2
    )
    let extracted = NSImage(size: cropRect.size)
    extracted.lockFocus()
    image.draw(
        at: NSPoint(x: -cropRect.origin.x, y: -cropRect.origin.y),
        from: .zero,
        operation: .copy,
        fraction: 1.0
    )
    extracted.unlockFocus()
    return extracted
}

func roundedPath(_ rect: NSRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func drawGradient(in rect: NSRect, top: NSColor, bottom: NSColor) {
    NSGradient(colors: [top, bottom])!.draw(in: rect, angle: -90)
}

func renderPremiumIcon(baseImage: NSImage, variant: PremiumVariant) throws {
    let canvasSize = NSSize(width: 1024, height: 1024)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvasSize.width),
        pixelsHigh: Int(canvasSize.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    let tileRect = NSRect(x: 74, y: 74, width: 876, height: 876)
    let tileRadius: CGFloat = 150
    let iconInset: CGFloat = 92
    let iconRect = tileRect.insetBy(dx: iconInset, dy: iconInset)
    let imageRect = NSRect(
        x: iconRect.minX - 18,
        y: iconRect.minY - 18,
        width: iconRect.width + 36,
        height: iconRect.height + 36
    )

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    NSColor.clear.setFill()
    NSRect(origin: .zero, size: canvasSize).fill()

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = variant.shadowColor
    shadow.shadowBlurRadius = variant.shadowBlur
    shadow.shadowOffset = NSSize(width: 0, height: variant.shadowYOffset)
    shadow.set()
    let shadowTilePath = roundedPath(tileRect, radius: tileRadius)
    variant.fillBottom.setFill()
    shadowTilePath.fill()
    NSGraphicsContext.restoreGraphicsState()

    let tilePath = roundedPath(tileRect, radius: tileRadius)
    tilePath.addClip()
    drawGradient(in: tileRect, top: variant.fillTop, bottom: variant.fillBottom)

    let topGlossRect = NSRect(x: tileRect.minX, y: tileRect.midY, width: tileRect.width, height: tileRect.height / 2)
    let glossPath = roundedPath(topGlossRect, radius: tileRadius)
    NSColor.white.withAlphaComponent(0.10).setFill()
    glossPath.fill()

    let innerShadow = NSShadow()
    innerShadow.shadowColor = NSColor.black.withAlphaComponent(0.10)
    innerShadow.shadowBlurRadius = 20
    innerShadow.shadowOffset = NSSize(width: 0, height: -6)
    NSGraphicsContext.saveGraphicsState()
    innerShadow.set()
    variant.overlay.setFill()
    roundedPath(tileRect, radius: tileRadius).fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    roundedPath(tileRect, radius: tileRadius).addClip()
    baseImage.draw(in: imageRect, from: .zero, operation: .sourceOver, fraction: 0.94)
    variant.overlay.setFill()
    NSRect(origin: .zero, size: canvasSize).fill(using: .sourceAtop)
    NSGraphicsContext.restoreGraphicsState()

    let borderPath = roundedPath(tileRect.insetBy(dx: 2, dy: 2), radius: tileRadius - 2)
    borderPath.lineWidth = 4
    variant.border.setStroke()
    borderPath.stroke()

    let highlightPath = roundedPath(tileRect.insetBy(dx: 8, dy: 8), radius: tileRadius - 8)
    highlightPath.lineWidth = 2
    NSColor.white.withAlphaComponent(0.18).setStroke()
    highlightPath.stroke()

    NSGraphicsContext.restoreGraphicsState()

    let outputURL = outputDir.appendingPathComponent(variant.fileName)
    try rep.representation(using: .png, properties: [:])!.write(to: outputURL)
}

try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
let original = loadImage(sourceURL)
let extracted = extractSourceTile(original)
for variant in variants {
    try renderPremiumIcon(baseImage: extracted, variant: variant)
    print("Rendered \(variant.title)")
}
