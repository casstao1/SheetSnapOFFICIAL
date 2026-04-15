import AppKit
import Foundation

let repoRoot = URL(fileURLWithPath: "/Users/castao/Desktop/SheetSnap/SheetSnapOFFICIAL")
let outputDir = repoRoot.appendingPathComponent("docs/app-store/icon-redesign", isDirectory: true)

struct IconTheme {
    let fileName: String
    let title: String
    let top: NSColor
    let bottom: NSColor
    let stroke: NSColor
    let grid: NSColor
    let accentCell: NSColor
    let gloss: NSColor
}

let themes: [IconTheme] = [
    .init(
        fileName: "SheetSnapIcon-redesign-teal.png",
        title: "Redesign Teal",
        top: NSColor(calibratedRed: 0.69, green: 0.89, blue: 0.84, alpha: 1.0),
        bottom: NSColor(calibratedRed: 0.30, green: 0.69, blue: 0.70, alpha: 1.0),
        stroke: NSColor(calibratedRed: 0.23, green: 0.34, blue: 0.42, alpha: 1.0),
        grid: NSColor(calibratedRed: 0.53, green: 0.66, blue: 0.73, alpha: 1.0),
        accentCell: NSColor(calibratedRed: 0.46, green: 0.83, blue: 0.72, alpha: 1.0),
        gloss: NSColor.white.withAlphaComponent(0.20)
    ),
    .init(
        fileName: "SheetSnapIcon-redesign-deep.png",
        title: "Redesign Deep",
        top: NSColor(calibratedRed: 0.58, green: 0.84, blue: 0.80, alpha: 1.0),
        bottom: NSColor(calibratedRed: 0.20, green: 0.56, blue: 0.60, alpha: 1.0),
        stroke: NSColor(calibratedRed: 0.18, green: 0.27, blue: 0.34, alpha: 1.0),
        grid: NSColor(calibratedRed: 0.47, green: 0.62, blue: 0.70, alpha: 1.0),
        accentCell: NSColor(calibratedRed: 0.39, green: 0.79, blue: 0.69, alpha: 1.0),
        gloss: NSColor.white.withAlphaComponent(0.14)
    )
]

func roundedPath(_ rect: NSRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func fillGradient(_ rect: NSRect, top: NSColor, bottom: NSColor) {
    NSGradient(colors: [top, bottom])!.draw(in: rect, angle: -90)
}

func strokePath(_ path: NSBezierPath, color: NSColor, width: CGFloat) {
    path.lineWidth = width
    color.setStroke()
    path.stroke()
}

func fillPath(_ path: NSBezierPath, color: NSColor) {
    color.setFill()
    path.fill()
}

func drawWindowGlyph(in rect: NSRect, theme: IconTheme) {
    let outer = roundedPath(rect, radius: 34)
    fillPath(outer, color: NSColor.white.withAlphaComponent(0.24))
    strokePath(outer, color: theme.stroke.withAlphaComponent(0.88), width: 10)

    let innerRect = rect.insetBy(dx: 18, dy: 18)
    let inner = roundedPath(innerRect, radius: 24)
    fillPath(inner, color: NSColor.white.withAlphaComponent(0.74))

    let headerHeight = rect.height * 0.18
    let headerRect = NSRect(x: innerRect.minX, y: innerRect.maxY - headerHeight, width: innerRect.width, height: headerHeight)
    let headerPath = NSBezierPath(rect: headerRect)
    fillPath(headerPath, color: NSColor.white.withAlphaComponent(0.18))
    strokePath(headerPath, color: theme.stroke.withAlphaComponent(0.32), width: 2)

    let dotSize: CGFloat = 18
    let dotY = headerRect.midY - dotSize / 2
    let dotX = innerRect.minX + 22
    for (index, color) in [NSColor.systemRed.withAlphaComponent(0.75), NSColor.white.withAlphaComponent(0.95), NSColor.white.withAlphaComponent(0.95)].enumerated() {
        let rect = NSRect(x: dotX + CGFloat(index) * 34, y: dotY, width: dotSize, height: dotSize)
        fillPath(NSBezierPath(ovalIn: rect), color: color)
    }

    let contentRect = NSRect(x: innerRect.minX + 8, y: innerRect.minY + 8, width: innerRect.width - 16, height: innerRect.height - headerHeight - 18)
    let leftColumnWidth = contentRect.width * 0.24
    let rowCount = 5
    let colCount = 3
    let rowHeight = contentRect.height / CGFloat(rowCount)
    let colWidth = (contentRect.width - leftColumnWidth) / CGFloat(colCount)

    let verticalMain = NSBezierPath()
    verticalMain.move(to: NSPoint(x: contentRect.minX + leftColumnWidth, y: contentRect.minY))
    verticalMain.line(to: NSPoint(x: contentRect.minX + leftColumnWidth, y: contentRect.maxY))
    strokePath(verticalMain, color: theme.stroke.withAlphaComponent(0.62), width: 8)

    for row in 1..<rowCount {
        let y = contentRect.minY + CGFloat(row) * rowHeight
        let path = NSBezierPath()
        path.move(to: NSPoint(x: contentRect.minX, y: y))
        path.line(to: NSPoint(x: contentRect.maxX, y: y))
        strokePath(path, color: theme.grid.withAlphaComponent(0.78), width: 7)
    }

    for col in 1..<colCount {
        let x = contentRect.minX + leftColumnWidth + CGFloat(col) * colWidth
        let path = NSBezierPath()
        path.move(to: NSPoint(x: x, y: contentRect.minY))
        path.line(to: NSPoint(x: x, y: contentRect.maxY))
        strokePath(path, color: theme.grid.withAlphaComponent(0.66), width: 6)
    }

    let accentRect = NSRect(x: contentRect.minX, y: contentRect.minY, width: leftColumnWidth, height: rowHeight)
    fillPath(NSBezierPath(rect: accentRect), color: theme.accentCell.withAlphaComponent(0.85))

    let foldPath = NSBezierPath()
    foldPath.move(to: NSPoint(x: contentRect.maxX - 78, y: contentRect.minY))
    foldPath.line(to: NSPoint(x: contentRect.maxX, y: contentRect.minY))
    foldPath.line(to: NSPoint(x: contentRect.maxX, y: contentRect.minY + 52))
    foldPath.close()
    fillPath(foldPath, color: NSColor(calibratedWhite: 0.92, alpha: 0.78))
}

func renderIcon(theme: IconTheme) throws {
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

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    NSColor.clear.setFill()
    NSRect(origin: .zero, size: canvasSize).fill()

    let tileRect = NSRect(x: 74, y: 74, width: 876, height: 876)
    let tileRadius: CGFloat = 156

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
    shadow.shadowBlurRadius = 28
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.set()
    let base = roundedPath(tileRect, radius: tileRadius)
    fillPath(base, color: theme.bottom)
    NSGraphicsContext.restoreGraphicsState()

    let clip = roundedPath(tileRect, radius: tileRadius)
    clip.addClip()
    fillGradient(tileRect, top: theme.top, bottom: theme.bottom)

    let topGlow = NSBezierPath(ovalIn: NSRect(x: tileRect.minX - 60, y: tileRect.midY + 120, width: 540, height: 380))
    fillPath(topGlow, color: theme.gloss)
    let bottomGlow = NSBezierPath(ovalIn: NSRect(x: tileRect.maxX - 430, y: tileRect.minY - 40, width: 360, height: 240))
    fillPath(bottomGlow, color: NSColor.white.withAlphaComponent(0.08))

    let innerBorder = roundedPath(tileRect.insetBy(dx: 4, dy: 4), radius: tileRadius - 4)
    strokePath(innerBorder, color: NSColor.white.withAlphaComponent(0.18), width: 3)
    let outerBorder = roundedPath(tileRect.insetBy(dx: 1.5, dy: 1.5), radius: tileRadius - 1.5)
    strokePath(outerBorder, color: theme.stroke.withAlphaComponent(0.18), width: 2)

    let glyphRect = NSRect(x: 247, y: 274, width: 530, height: 444)
    drawWindowGlyph(in: glyphRect, theme: theme)

    NSGraphicsContext.restoreGraphicsState()

    let outputURL = outputDir.appendingPathComponent(theme.fileName)
    try rep.representation(using: .png, properties: [:])!.write(to: outputURL)
}

try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
for theme in themes {
    try renderIcon(theme: theme)
    print("Rendered \(theme.title)")
}
