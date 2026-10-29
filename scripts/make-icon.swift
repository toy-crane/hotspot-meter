// Draws the app icon and writes Resources/AppIcon.icns.
// Usage: swift scripts/make-icon.swift
//
// The glyph is drawn by hand because SF Symbols may not be used in app icons.
import AppKit

let canvas: CGFloat = 1024

func drawIcon(in context: CGContext) {
    // macOS icon grid: an 824pt rounded square centered on a 1024pt canvas.
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    let tilePath = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: NSColor.black.withAlphaComponent(0.3).cgColor)
    context.addPath(tilePath)
    context.setFillColor(NSColor.black.cgColor)
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(tilePath)
    context.clip()
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            NSColor(srgbRed: 0.29, green: 0.64, blue: 1.0, alpha: 1).cgColor,
            NSColor(srgbRed: 0.04, green: 0.42, blue: 1.0, alpha: 1).cgColor,
        ] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: tile.maxY), end: CGPoint(x: 0, y: tile.minY), options: [])
    context.restoreGState()

    // Two interlocking chain links, tilted 45 degrees.
    context.saveGState()
    context.translateBy(x: canvas / 2, y: canvas / 2)
    context.rotate(by: .pi / 4)
    context.setStrokeColor(NSColor.white.cgColor)
    context.setLineWidth(54)
    let link = CGSize(width: 300, height: 170)
    for offset: CGFloat in [-112, 112] {
        let rect = CGRect(x: offset - link.width / 2, y: -link.height / 2, width: link.width, height: link.height)
        context.addPath(CGPath(roundedRect: rect, cornerWidth: link.height / 2, cornerHeight: link.height / 2, transform: nil))
        context.strokePath()
    }
    context.restoreGState()
}

func png(size: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    let graphics = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = graphics
    let context = graphics.cgContext
    context.scaleBy(x: CGFloat(size) / canvas, y: CGFloat(size) / canvas)
    drawIcon(in: context)
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for points in [16, 32, 128, 256, 512] {
    try png(size: points).write(to: iconset.appendingPathComponent("icon_\(points)x\(points).png"))
    try png(size: points * 2).write(to: iconset.appendingPathComponent("icon_\(points)x\(points)@2x.png"))
}

let resources = root.appendingPathComponent("Resources")
try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", resources.appendingPathComponent("AppIcon.icns").path]
try iconutil.run()
iconutil.waitUntilExit()
print("Wrote Resources/AppIcon.icns")
