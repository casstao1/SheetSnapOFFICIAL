import AppKit
import Foundation

let sourceURL = URL(fileURLWithPath: "/Users/castao/Desktop/freepik_make-this-reference-image_2794538417.png")
let iconSetURL = URL(fileURLWithPath: "/Users/castao/Desktop/SheetSnap/SheetSnapOFFICIAL/SheetSnap/Assets.xcassets/AppIcon.appiconset")

struct IconSpec {
    let filename: String
    let pixels: Int
    let size: String
    let scale: String?
    let idiom: String
    let platform: String?
}

let specs: [IconSpec] = [
    .init(filename: "appicon-1024.png", pixels: 1024, size: "1024x1024", scale: nil, idiom: "universal", platform: "ios"),
    .init(filename: "appicon-16.png", pixels: 16, size: "16x16", scale: "1x", idiom: "mac", platform: nil),
    .init(filename: "appicon-32.png", pixels: 32, size: "16x16", scale: "2x", idiom: "mac", platform: nil),
    .init(filename: "appicon-32-1x.png", pixels: 32, size: "32x32", scale: "1x", idiom: "mac", platform: nil),
    .init(filename: "appicon-64.png", pixels: 64, size: "32x32", scale: "2x", idiom: "mac", platform: nil),
    .init(filename: "appicon-128.png", pixels: 128, size: "128x128", scale: "1x", idiom: "mac", platform: nil),
    .init(filename: "appicon-256.png", pixels: 256, size: "128x128", scale: "2x", idiom: "mac", platform: nil),
    .init(filename: "appicon-256-1x.png", pixels: 256, size: "256x256", scale: "1x", idiom: "mac", platform: nil),
    .init(filename: "appicon-512.png", pixels: 512, size: "256x256", scale: "2x", idiom: "mac", platform: nil),
    .init(filename: "appicon-512-1x.png", pixels: 512, size: "512x512", scale: "1x", idiom: "mac", platform: nil),
    .init(filename: "appicon-1024-mac.png", pixels: 1024, size: "512x512", scale: "2x", idiom: "mac", platform: nil)
]

func loadImage() -> NSImage {
    guard let image = NSImage(contentsOf: sourceURL) else {
        fatalError("Unable to load source image")
    }
    return image
}

func squareCrop(_ image: NSImage) -> NSImage {
    let side = min(image.size.width, image.size.height)
    let cropRect = NSRect(
        x: (image.size.width - side) / 2.0,
        y: (image.size.height - side) / 2.0,
        width: side,
        height: side
    )

    let cropped = NSImage(size: NSSize(width: side, height: side))
    cropped.lockFocus()
    image.draw(
        in: NSRect(origin: .zero, size: cropped.size),
        from: cropRect,
        operation: .copy,
        fraction: 1.0
    )
    cropped.unlockFocus()
    return cropped
}

func resizedImage(_ image: NSImage, pixels: Int) -> Data {
    let targetSize = NSSize(width: pixels, height: pixels)
    let out = NSImage(size: targetSize)
    out.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    image.draw(in: NSRect(origin: .zero, size: targetSize), from: .zero, operation: .copy, fraction: 1.0)
    out.unlockFocus()

    guard let tiff = out.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("Unable to encode resized image")
    }
    return png
}

try FileManager.default.createDirectory(at: iconSetURL, withIntermediateDirectories: true)

let baseImage = squareCrop(loadImage())
var imagesJSON: [[String: Any]] = []

for spec in specs {
    let fileURL = iconSetURL.appendingPathComponent(spec.filename)
    try resizedImage(baseImage, pixels: spec.pixels).write(to: fileURL)

    var entry: [String: Any] = [
        "filename": spec.filename,
        "idiom": spec.idiom,
        "size": spec.size
    ]
    if let scale = spec.scale {
        entry["scale"] = scale
    }
    if let platform = spec.platform {
        entry["platform"] = platform
    }
    imagesJSON.append(entry)
}

let contents: [String: Any] = [
    "images": imagesJSON,
    "info": [
        "author": "xcode",
        "version": 1
    ]
]

let jsonData = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try jsonData.write(to: iconSetURL.appendingPathComponent("Contents.json"))

print("Built AppIcon set in \(iconSetURL.path)")
