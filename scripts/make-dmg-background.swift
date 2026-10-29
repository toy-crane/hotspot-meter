// Draws the DMG window background and writes Resources/dmg-background.tiff
// (1x and 2x in one file, as Finder expects).
// Usage: swift scripts/make-dmg-background.swift
//
// Layout must match scripts/make-dmg.sh: a 600x380 window with the app icon
// centered at (150, 180) and the Applications link at (450, 180).
import AppKit

let size = NSSize(width: 600, height: 380)

func render(scale: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(size.width) * scale, pixelsHigh: Int(size.height) * scale,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let canvas = NSRect(origin: .zero, size: size)
    NSGradient(colors: [
        NSColor(srgbRed: 0.97, green: 0.98, blue: 1.0, alpha: 1),
        NSColor(srgbRed: 0.90, green: 0.94, blue: 1.0, alpha: 1),
    ])!.draw(in: canvas, angle: -90)

    // Arrow from the app icon toward Applications (Finder y runs top-down; AppKit bottom-up).
    let arrowY = size.height - 180
    let arrow = NSBezierPath()
    arrow.move(to: NSPoint(x: 245, y: arrowY))
    arrow.line(to: NSPoint(x: 345, y: arrowY))
    arrow.move(to: NSPoint(x: 330, y: arrowY + 14))
    arrow.line(to: NSPoint(x: 348, y: arrowY))
    arrow.line(to: NSPoint(x: 330, y: arrowY - 14))
    arrow.lineWidth = 6
    arrow.lineCapStyle = .round
    arrow.lineJoinStyle = .round
    NSColor(srgbRed: 0.04, green: 0.42, blue: 1.0, alpha: 0.55).setStroke()
    arrow.stroke()

    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let caption = NSAttributedString(string: "Applications 폴더로 끌어다 놓으세요", attributes: [
        .font: NSFont.systemFont(ofSize: 15, weight: .medium),
        .foregroundColor: NSColor(srgbRed: 0.25, green: 0.3, blue: 0.4, alpha: 1),
        .paragraphStyle: paragraph,
    ])
    caption.draw(in: NSRect(x: 0, y: 60, width: size.width, height: 24))

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let temp = FileManager.default.temporaryDirectory
let oneX = temp.appendingPathComponent("dmg-background.png")
let twoX = temp.appendingPathComponent("dmg-background@2x.png")
try render(scale: 1).write(to: oneX)
try render(scale: 2).write(to: twoX)

let tiffutil = Process()
tiffutil.executableURL = URL(fileURLWithPath: "/usr/bin/tiffutil")
tiffutil.arguments = ["-cathidpicheck", oneX.path, twoX.path, "-out", root.appendingPathComponent("Resources/dmg-background.tiff").path]
try tiffutil.run()
tiffutil.waitUntilExit()
print("Wrote Resources/dmg-background.tiff")
