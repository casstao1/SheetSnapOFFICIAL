import AppKit
import Foundation

struct SlideTheme {
    let name: String
    let source: String
    let titleLeading: String
    let titleAccent: String
    let subtitle: String
    let accent: NSColor
    let accentSecondary: NSColor
    let badge: String
}

struct RenderStyle {
    let outputFolder: String
    let backgroundStart: NSColor
    let backgroundEnd: NSColor
    let cardFill: NSColor
    let cardInset: CGFloat
    let screenshotInset: CGFloat
    let headlineColor: NSColor
    let subtitleColor: NSColor
    let shadowOpacity: CGFloat
    let borderColor: NSColor
    let topRightFillOpacity: CGFloat
    let bottomLeftFillOpacity: CGFloat
    let circleOpacityPrimary: CGFloat
    let circleOpacitySecondary: CGFloat
}

let repoRoot = URL(fileURLWithPath: "/Users/castao/Desktop/SheetSnap/SheetSnapOFFICIAL")
let screenshotsDir = repoRoot.appendingPathComponent("docs/app-store/screenshots", isDirectory: true)

let slides: [SlideTheme] = [
    .init(
        name: "01-import-marketing.png",
        source: "01-import-screen.png",
        titleLeading: "Drop a photo and",
        titleAccent: "capture the table",
        subtitle: "Import screenshots, scans, or photos and turn them into structured spreadsheet data in seconds.",
        accent: NSColor(calibratedRed: 0.11, green: 0.55, blue: 0.66, alpha: 1.0),
        accentSecondary: NSColor(calibratedRed: 0.52, green: 0.81, blue: 0.77, alpha: 1.0),
        badge: "Import"
    ),
    .init(
        name: "02-processing-marketing.png",
        source: "02-processing-screen.png",
        titleLeading: "Extract rows and",
        titleAccent: "clean columns",
        subtitle: "SheetSnap reads visible grid structure automatically so you spend less time rebuilding tables by hand.",
        accent: NSColor(calibratedRed: 0.19, green: 0.42, blue: 0.83, alpha: 1.0),
        accentSecondary: NSColor(calibratedRed: 0.55, green: 0.73, blue: 0.95, alpha: 1.0),
        badge: "OCR"
    ),
    .init(
        name: "03-results-marketing.png",
        source: "03-result-screen.png",
        titleLeading: "Review the output",
        titleAccent: "before export",
        subtitle: "Inspect extracted rows, confirm headers, and copy clean table data into Sheets, Excel, or CSV.",
        accent: NSColor(calibratedRed: 0.24, green: 0.58, blue: 0.42, alpha: 1.0),
        accentSecondary: NSColor(calibratedRed: 0.69, green: 0.85, blue: 0.67, alpha: 1.0),
        badge: "Results"
    ),
    .init(
        name: "04-history-marketing.png",
        source: "04-history-screen.png",
        titleLeading: "Keep every table",
        titleAccent: "within reach",
        subtitle: "Reopen recent extractions instantly and continue working without repeating the import step.",
        accent: NSColor(calibratedRed: 0.36, green: 0.57, blue: 0.29, alpha: 1.0),
        accentSecondary: NSColor(calibratedRed: 0.74, green: 0.84, blue: 0.57, alpha: 1.0),
        badge: "History"
    ),
    .init(
        name: "05-editing-marketing.png",
        source: "05-editing-screen.png",
        titleLeading: "Fix cells with",
        titleAccent: "native editing",
        subtitle: "Adjust text directly in the extracted table before you copy, save CSV, or export an Excel file.",
        accent: NSColor(calibratedRed: 0.18, green: 0.60, blue: 0.50, alpha: 1.0),
        accentSecondary: NSColor(calibratedRed: 0.63, green: 0.84, blue: 0.74, alpha: 1.0),
        badge: "Edit"
    )
]

let canvasSize = NSSize(width: 2560, height: 1600)

let styles: [RenderStyle] = [
    .init(
        outputFolder: "docs/app-store/marketing-screenshots",
        backgroundStart: NSColor(calibratedRed: 0.97, green: 0.98, blue: 0.96, alpha: 1.0),
        backgroundEnd: NSColor(calibratedRed: 0.95, green: 0.97, blue: 0.95, alpha: 1.0),
        cardFill: NSColor.white,
        cardInset: 250,
        screenshotInset: 58,
        headlineColor: NSColor(calibratedWhite: 0.08, alpha: 1.0),
        subtitleColor: NSColor(calibratedWhite: 0.24, alpha: 1.0),
        shadowOpacity: 0.14,
        borderColor: NSColor(calibratedWhite: 1.0, alpha: 0.65),
        topRightFillOpacity: 0.92,
        bottomLeftFillOpacity: 0.90,
        circleOpacityPrimary: 0.08,
        circleOpacitySecondary: 0.12
    ),
    .init(
        outputFolder: "docs/app-store/marketing-screenshots-premium",
        backgroundStart: NSColor(calibratedRed: 0.06, green: 0.09, blue: 0.12, alpha: 1.0),
        backgroundEnd: NSColor(calibratedRed: 0.04, green: 0.06, blue: 0.09, alpha: 1.0),
        cardFill: NSColor(calibratedRed: 0.09, green: 0.11, blue: 0.15, alpha: 1.0),
        cardInset: 210,
        screenshotInset: 44,
        headlineColor: NSColor(calibratedWhite: 0.98, alpha: 1.0),
        subtitleColor: NSColor(calibratedWhite: 0.83, alpha: 1.0),
        shadowOpacity: 0.28,
        borderColor: NSColor(calibratedWhite: 1.0, alpha: 0.16),
        topRightFillOpacity: 0.96,
        bottomLeftFillOpacity: 0.84,
        circleOpacityPrimary: 0.16,
        circleOpacitySecondary: 0.20
    )
]

func paragraphStyle(_ alignment: NSTextAlignment, lineHeight: CGFloat? = nil) -> NSMutableParagraphStyle {
    let style = NSMutableParagraphStyle()
    style.alignment = alignment
    if let lineHeight {
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
    }
    return style
}

func makeGradientImage(size: NSSize, start: NSColor, end: NSColor) {
    let gradient = NSGradient(colors: [start, end])!
    gradient.draw(in: NSRect(origin: .zero, size: size), angle: 90)
}

func drawPolygon(points: [NSPoint], color: NSColor) {
    guard let first = points.first else { return }
    let path = NSBezierPath()
    path.move(to: first)
    for point in points.dropFirst() {
        path.line(to: point)
    }
    path.close()
    color.setFill()
    path.fill()
}

func drawCircle(center: NSPoint, radius: CGFloat, color: NSColor) {
    let rect = NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    let path = NSBezierPath(ovalIn: rect)
    color.setFill()
    path.fill()
}

func drawRoundedRect(_ rect: NSRect, radius: CGFloat, fill: NSColor) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    fill.setFill()
    path.fill()
}

func drawShadowedCard(_ rect: NSRect, radius: CGFloat, fill: NSColor, shadowOpacity: CGFloat) {
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowBlurRadius = 30
    shadow.shadowOffset = NSSize(width: 0, height: -14)
    shadow.shadowColor = NSColor(calibratedWhite: 0, alpha: shadowOpacity)
    shadow.set()
    drawRoundedRect(rect, radius: radius, fill: fill)
    NSGraphicsContext.restoreGraphicsState()
}

func drawBorder(_ rect: NSRect, radius: CGFloat, color: NSColor, width: CGFloat) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    path.lineWidth = width
    color.setStroke()
    path.stroke()
}

func drawText(_ string: String, rect: NSRect, font: NSFont, color: NSColor, alignment: NSTextAlignment = .left, lineHeight: CGFloat? = nil) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraphStyle(alignment, lineHeight: lineHeight)
    ]
    NSString(string: string).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes)
}

func measuredWidth(_ string: String, font: NSFont) -> CGFloat {
    let attrs: [NSAttributedString.Key: Any] = [.font: font]
    return NSString(string: string).size(withAttributes: attrs).width
}

func drawHeadline(leading: String, accent: String, y: CGFloat, baseColor: NSColor, accentColor: NSColor) {
    let baseFont = NSFont.systemFont(ofSize: 84, weight: .bold)
    let accentFont = NSFont.systemFont(ofSize: 84, weight: .heavy)
    let gap: CGFloat = 18
    let leadWidth = measuredWidth(leading, font: baseFont)
    let accentWidth = measuredWidth(accent, font: accentFont)
    let totalWidth = leadWidth + gap + accentWidth
    let startX = (canvasSize.width - totalWidth) / 2.0
    drawText(leading, rect: NSRect(x: startX, y: y, width: leadWidth + 12, height: 100), font: baseFont, color: baseColor)
    drawText(accent, rect: NSRect(x: startX + leadWidth + gap, y: y, width: accentWidth + 16, height: 100), font: accentFont, color: accentColor)
}

func scaledImageRect(imageSize: NSSize, maxRect: NSRect) -> NSRect {
    let widthRatio = maxRect.width / imageSize.width
    let heightRatio = maxRect.height / imageSize.height
    let ratio = min(widthRatio, heightRatio)
    let size = NSSize(width: imageSize.width * ratio, height: imageSize.height * ratio)
    return NSRect(
        x: maxRect.midX - size.width / 2.0,
        y: maxRect.midY - size.height / 2.0,
        width: size.width,
        height: size.height
    )
}

func drawScreenshot(_ image: NSImage, in rect: NSRect, radius: CGFloat) {
    NSGraphicsContext.saveGraphicsState()
    let clipPath = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    clipPath.addClip()
    image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()
    drawBorder(rect, radius: radius, color: NSColor(calibratedWhite: 1.0, alpha: 0.65), width: 2)
}

func makeMarketingSlide(theme: SlideTheme, style: RenderStyle, outputDir: URL) throws {
    let sourceURL = screenshotsDir.appendingPathComponent(theme.source)
    guard let screenshot = NSImage(contentsOf: sourceURL) else {
        throw NSError(domain: "render", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing source image \(theme.source)"])
    }

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

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    makeGradientImage(size: canvasSize, start: style.backgroundStart, end: style.backgroundEnd)

    drawCircle(center: NSPoint(x: 360, y: 1320), radius: 220, color: theme.accent.withAlphaComponent(style.circleOpacityPrimary))
    drawCircle(center: NSPoint(x: 2200, y: 360), radius: 260, color: theme.accentSecondary.withAlphaComponent(style.circleOpacitySecondary))
    drawCircle(center: NSPoint(x: 2050, y: 1380), radius: 120, color: theme.accent.withAlphaComponent(style.circleOpacityPrimary * 0.7))

    drawPolygon(
        points: [
            NSPoint(x: canvasSize.width * 0.78, y: canvasSize.height),
            NSPoint(x: canvasSize.width, y: canvasSize.height),
            NSPoint(x: canvasSize.width, y: canvasSize.height * 0.66)
        ],
        color: theme.accent.withAlphaComponent(style.topRightFillOpacity)
    )
    drawPolygon(
        points: [
            NSPoint(x: 0, y: 0),
            NSPoint(x: canvasSize.width * 0.24, y: 0),
            NSPoint(x: 0, y: canvasSize.height * 0.18)
        ],
        color: theme.accentSecondary.withAlphaComponent(style.bottomLeftFillOpacity)
    )

    let pillRect = NSRect(x: 120, y: 1380, width: 180, height: 52)
    drawRoundedRect(pillRect, radius: 26, fill: theme.accent.withAlphaComponent(0.12))
    drawText(theme.badge, rect: NSRect(x: pillRect.minX, y: pillRect.minY + 11, width: pillRect.width, height: 30), font: NSFont.systemFont(ofSize: 26, weight: .semibold), color: theme.accent, alignment: .center)

    drawHeadline(leading: theme.titleLeading, accent: theme.titleAccent, y: 1280, baseColor: style.headlineColor, accentColor: theme.accent)

    drawText(
        theme.subtitle,
        rect: NSRect(x: 360, y: 1190, width: 1840, height: 80),
        font: NSFont.systemFont(ofSize: 34, weight: .regular),
        color: style.subtitleColor,
        alignment: .center,
        lineHeight: 42
    )

    let cardRect = NSRect(
        x: style.cardInset,
        y: 130,
        width: canvasSize.width - (style.cardInset * 2),
        height: 950
    )
    drawShadowedCard(cardRect, radius: 42, fill: style.cardFill, shadowOpacity: style.shadowOpacity)

    let screenshotArea = cardRect.insetBy(dx: style.screenshotInset, dy: style.screenshotInset)
    let fittedRect = scaledImageRect(imageSize: screenshot.size, maxRect: screenshotArea)
    drawScreenshot(screenshot, in: fittedRect, radius: 28)

    if style.outputFolder.hasSuffix("premium") {
        drawBorder(cardRect, radius: 42, color: style.borderColor, width: 2)
        let glowRect = NSRect(x: fittedRect.minX - 24, y: fittedRect.minY - 24, width: fittedRect.width + 48, height: fittedRect.height + 48)
        NSGraphicsContext.saveGraphicsState()
        let glow = NSShadow()
        glow.shadowBlurRadius = 40
        glow.shadowOffset = .zero
        glow.shadowColor = theme.accent.withAlphaComponent(0.28)
        glow.set()
        let glowPath = NSBezierPath(roundedRect: glowRect, xRadius: 34, yRadius: 34)
        NSColor.clear.setFill()
        glowPath.fill()
        NSGraphicsContext.restoreGraphicsState()
    }

    NSGraphicsContext.restoreGraphicsState()

    let outputURL = outputDir.appendingPathComponent(theme.name)
    let pngData = rep.representation(using: .png, properties: [:])!
    try pngData.write(to: outputURL)
}

for style in styles {
    let outputDir = repoRoot.appendingPathComponent(style.outputFolder, isDirectory: true)
    try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
    for slide in slides {
        try makeMarketingSlide(theme: slide, style: style, outputDir: outputDir)
        print("Rendered \(style.outputFolder)/\(slide.name)")
    }
}
