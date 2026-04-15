import AppKit
import Foundation

let sourceURL = URL(fileURLWithPath: "/Users/castao/Desktop/freepik_make-an-minimal-aesthetic_2785311228.png")
let repoRoot = URL(fileURLWithPath: "/Users/castao/Desktop/SheetSnap/SheetSnapOFFICIAL")
let outputDir = repoRoot.appendingPathComponent("docs/app-store/icon-review", isDirectory: true)

struct Variant {
    let fileName: String
    let title: String
    let subtitle: String
    let accent: NSColor
    let bgStart: NSColor
    let bgEnd: NSColor
}

let variants: [Variant] = [
    .init(
        fileName: "01-light-dark-review.png",
        title: "Original icon on light and dark surfaces",
        subtitle: "This checks contrast and edge clarity against both Finder-style backgrounds.",
        accent: NSColor(calibratedRed: 0.31, green: 0.73, blue: 0.66, alpha: 1.0),
        bgStart: NSColor(calibratedWhite: 0.97, alpha: 1.0),
        bgEnd: NSColor(calibratedWhite: 0.93, alpha: 1.0)
    ),
    .init(
        fileName: "02-premium-teal.png",
        title: "Premium teal presentation",
        subtitle: "A richer dark stage makes the icon feel more premium without changing the icon itself.",
        accent: NSColor(calibratedRed: 0.28, green: 0.79, blue: 0.72, alpha: 1.0),
        bgStart: NSColor(calibratedRed: 0.05, green: 0.10, blue: 0.13, alpha: 1.0),
        bgEnd: NSColor(calibratedRed: 0.03, green: 0.07, blue: 0.10, alpha: 1.0)
    ),
    .init(
        fileName: "03-premium-graphite.png",
        title: "Premium graphite presentation",
        subtitle: "A graphite backdrop adds weight and makes the turquoise tile feel more deliberate.",
        accent: NSColor(calibratedRed: 0.55, green: 0.85, blue: 0.80, alpha: 1.0),
        bgStart: NSColor(calibratedRed: 0.07, green: 0.08, blue: 0.11, alpha: 1.0),
        bgEnd: NSColor(calibratedRed: 0.03, green: 0.04, blue: 0.06, alpha: 1.0)
    ),
    .init(
        fileName: "04-premium-frosted.png",
        title: "Frosted glass presentation",
        subtitle: "A brighter macOS-style surface keeps the icon soft while feeling cleaner and more polished.",
        accent: NSColor(calibratedRed: 0.44, green: 0.82, blue: 0.78, alpha: 1.0),
        bgStart: NSColor(calibratedRed: 0.90, green: 0.96, blue: 0.95, alpha: 1.0),
        bgEnd: NSColor(calibratedRed: 0.82, green: 0.93, blue: 0.93, alpha: 1.0)
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

func cropNonWhite(_ image: NSImage) -> NSImage {
    let rep = pngRep(image)
    let width = rep.pixelsWide
    let height = rep.pixelsHigh

    var minX = width
    var minY = height
    var maxX = 0
    var maxY = 0
    let threshold: CGFloat = 0.97

    for y in 0..<height {
        for x in 0..<width {
            guard let color = rep.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { continue }
            if color.redComponent < threshold || color.greenComponent < threshold || color.blueComponent < threshold || color.alphaComponent < 0.99 {
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }
    }

    if minX >= maxX || minY >= maxY {
        return image
    }

    let cropRect = NSRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
    let cropped = NSImage(size: cropRect.size)
    cropped.lockFocus()
    image.draw(at: NSPoint(x: -cropRect.origin.x, y: -cropRect.origin.y), from: .zero, operation: .copy, fraction: 1.0)
    cropped.unlockFocus()
    return cropped
}

func paragraph(_ alignment: NSTextAlignment) -> NSMutableParagraphStyle {
    let p = NSMutableParagraphStyle()
    p.alignment = alignment
    return p
}

func drawText(_ text: String, rect: NSRect, font: NSFont, color: NSColor, alignment: NSTextAlignment = .center) {
    NSString(string: text).draw(
        with: rect,
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph(alignment)
        ]
    )
}

func drawGradient(_ rect: NSRect, start: NSColor, end: NSColor) {
    NSGradient(colors: [start, end])!.draw(in: rect, angle: 90)
}

func rounded(_ rect: NSRect, radius: CGFloat, fill: NSColor) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    fill.setFill()
    path.fill()
}

func strokeRounded(_ rect: NSRect, radius: CGFloat, color: NSColor, width: CGFloat) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    path.lineWidth = width
    color.setStroke()
    path.stroke()
}

func shadowedCard(_ rect: NSRect, radius: CGFloat, fill: NSColor, shadowColor: NSColor, blur: CGFloat, y: CGFloat) {
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = shadowColor
    shadow.shadowBlurRadius = blur
    shadow.shadowOffset = NSSize(width: 0, height: y)
    shadow.set()
    rounded(rect, radius: radius, fill: fill)
    NSGraphicsContext.restoreGraphicsState()
}

func drawMaskedIcon(_ image: NSImage, in rect: NSRect, cornerRadius: CGFloat) {
    NSGraphicsContext.saveGraphicsState()
    let clip = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    clip.addClip()
    image.draw(in: rect)
    NSGraphicsContext.restoreGraphicsState()
}

func drawIcon(_ image: NSImage, in rect: NSRect, glowColor: NSColor? = nil, glowBlur: CGFloat = 34) {
    let cornerRadius = min(rect.width, rect.height) * 0.18
    if let glowColor {
        NSGraphicsContext.saveGraphicsState()
        let glow = NSShadow()
        glow.shadowColor = glowColor
        glow.shadowBlurRadius = glowBlur
        glow.shadowOffset = .zero
        glow.set()
        drawMaskedIcon(image, in: rect, cornerRadius: cornerRadius)
        NSGraphicsContext.restoreGraphicsState()
    }
    drawMaskedIcon(image, in: rect, cornerRadius: cornerRadius)
}

func renderBoard(for icon: NSImage) throws {
    try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

    let boardSize = NSSize(width: 1800, height: 1320)
    let iconSize = NSSize(width: 760, height: 760)

    for variant in variants {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(boardSize.width),
            pixelsHigh: Int(boardSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

        let fullRect = NSRect(origin: .zero, size: boardSize)
        drawGradient(fullRect, start: variant.bgStart, end: variant.bgEnd)

        if variant.fileName == "01-light-dark-review.png" {
            let left = NSRect(x: 80, y: 220, width: 760, height: 760)
            let right = NSRect(x: 960, y: 220, width: 760, height: 760)
            shadowedCard(left, radius: 60, fill: NSColor.white, shadowColor: NSColor(calibratedWhite: 0, alpha: 0.12), blur: 30, y: -12)
            shadowedCard(right, radius: 60, fill: NSColor(calibratedRed: 0.10, green: 0.12, blue: 0.16, alpha: 1.0), shadowColor: NSColor(calibratedWhite: 0, alpha: 0.28), blur: 36, y: -16)

            let iconLeft = NSRect(x: left.midX - iconSize.width / 2, y: left.midY - iconSize.height / 2, width: iconSize.width, height: iconSize.height)
            let iconRight = NSRect(x: right.midX - iconSize.width / 2, y: right.midY - iconSize.height / 2, width: iconSize.width, height: iconSize.height)
            drawIcon(icon, in: iconLeft)
            drawIcon(icon, in: iconRight)

            icon.draw(in: NSRect(x: left.minX + 42, y: left.maxY - 170, width: 120, height: 120))
            icon.draw(in: NSRect(x: left.minX + 184, y: left.maxY - 128, width: 78, height: 78))
            icon.draw(in: NSRect(x: right.minX + 42, y: right.maxY - 170, width: 120, height: 120))
            icon.draw(in: NSRect(x: right.minX + 184, y: right.maxY - 128, width: 78, height: 78))

            drawText("Light background", rect: NSRect(x: left.minX, y: 150, width: left.width, height: 42), font: .systemFont(ofSize: 28, weight: .semibold), color: NSColor(calibratedWhite: 0.12, alpha: 1.0))
            drawText("Dark background", rect: NSRect(x: right.minX, y: 150, width: right.width, height: 42), font: .systemFont(ofSize: 28, weight: .semibold), color: NSColor.white)
        } else {
            let haloCenter = NSPoint(x: boardSize.width / 2, y: 660)
            let haloRect = NSRect(x: haloCenter.x - 360, y: haloCenter.y - 360, width: 720, height: 720)
            let halo = NSBezierPath(ovalIn: haloRect)
            variant.accent.withAlphaComponent(0.12).setFill()
            halo.fill()

            let platformRect = NSRect(x: 290, y: 180, width: 1220, height: 860)
            shadowedCard(
                platformRect,
                radius: 56,
                fill: NSColor(calibratedWhite: 1.0, alpha: variant.fileName == "04-premium-frosted.png" ? 0.16 : 0.08),
                shadowColor: NSColor(calibratedWhite: 0, alpha: 0.30),
                blur: 42,
                y: -18
            )
            strokeRounded(platformRect, radius: 56, color: NSColor.white.withAlphaComponent(0.14), width: 2)

            let iconRect = NSRect(x: boardSize.width / 2 - iconSize.width / 2, y: 270, width: iconSize.width, height: iconSize.height)
            drawIcon(icon, in: iconRect, glowColor: variant.accent.withAlphaComponent(variant.fileName == "03-premium-graphite.png" ? 0.26 : 0.20), glowBlur: variant.fileName == "03-premium-graphite.png" ? 48 : 34)
        }

        let titleColor = variant.fileName == "01-light-dark-review.png" ? NSColor(calibratedWhite: 0.10, alpha: 1.0) : NSColor.white
        let subtitleColor = variant.fileName == "01-light-dark-review.png" ? NSColor(calibratedWhite: 0.34, alpha: 1.0) : NSColor(calibratedWhite: 0.82, alpha: 1.0)
        drawText(variant.title, rect: NSRect(x: 180, y: 1170, width: 1440, height: 58), font: .systemFont(ofSize: 54, weight: .bold), color: titleColor, alignment: .left)
        drawText(variant.subtitle, rect: NSRect(x: 180, y: 1104, width: 1440, height: 60), font: .systemFont(ofSize: 28, weight: .regular), color: subtitleColor, alignment: .left)

        let outputURL = outputDir.appendingPathComponent(variant.fileName)
        try rep.representation(using: .png, properties: [:])!.write(to: outputURL)
    }
}

let original = loadImage(sourceURL)
let cropped = cropNonWhite(original)
try renderBoard(for: cropped)
print("Rendered icon review set to \(outputDir.path)")
