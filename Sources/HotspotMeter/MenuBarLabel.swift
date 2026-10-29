import AppKit
import HotspotMeterCore
import SwiftUI

/// Draws the menu bar item as a template image.
///
/// MenuBarExtra ignores styling on its label, so the item is rendered to an
/// image instead. Template images keep only alpha, which lets the dimmed
/// state follow both light and dark menu bars.
@MainActor
enum MenuBarLabel {
    static func image(total: UInt64, isCounting: Bool) -> NSImage {
        let content = HStack(spacing: 4) {
            Image(systemName: isCounting ? "personalhotspot" : "personalhotspot.slash")
            Text(UsageFormat.bytes(total))
                .monospacedDigit()
        }
        .font(.system(size: NSFont.menuBarFont(ofSize: 0).pointSize))
        .foregroundStyle(.black)
        .opacity(isCounting ? 1 : 0.45)

        let renderer = ImageRenderer(content: content)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        let image = renderer.nsImage ?? NSImage()
        image.isTemplate = true
        return image
    }
}
