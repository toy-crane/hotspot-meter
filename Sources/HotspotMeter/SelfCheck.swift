#if DEBUG
import AppKit
import SwiftUI

/// Debug-only runtime check: `HotspotMeter --self-check <dir>`.
///
/// Renders the app's own windows to PNG and drives the reset confirmation
/// with synthetic key presses, since the app can capture its own views
/// without screen recording permission.
@MainActor
enum SelfCheck {
    static func runIfRequested() {
        let arguments = CommandLine.arguments
        guard let index = arguments.firstIndex(of: "--self-check"), index + 1 < arguments.count else { return }
        let directory = URL(fileURLWithPath: arguments[index + 1])
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            run(in: directory)
            NSApp.terminate(nil)
        }
    }

    private static func run(in directory: URL) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var report: [String: String] = [:]
        let total: UInt64 = 1_876_491_418
        let since = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 27, hour: 21, minute: 14))!

        for (name, counting) in [("panel-counting", true), ("panel-off", false)] {
            let panel = UsagePanel(total: total, since: since, isCounting: counting, onReset: {}, onQuit: {})
            write(snapshot(panel), to: directory, name: name)
        }
        for (name, counting) in [("label-counting", true), ("label-off", false)] {
            let image = MenuBarLabel.image(total: total, isCounting: counting)
            report["\(name).size"] = "\(Int(image.size.width))x\(Int(image.size.height))"
            write(onWhite(image), to: directory, name: name)
        }
        report["symbols"] = ["personalhotspot", "personalhotspot.slash"]
            .map { "\($0)=\(NSImage(systemSymbolName: $0, accessibilityDescription: nil) != nil)" }
            .joined(separator: ",")

        report["windows"] = NSApp.windows.map { String(describing: type(of: $0)) }.joined(separator: ",")
        if let statusWindow = NSApp.windows.first(where: { String(describing: type(of: $0)).contains("StatusBar") }),
           let view = statusWindow.contentView {
            write(capture(view), to: directory, name: "statusbar-live")
        }

        let alert = ResetConfirmation.makeAlert(total: total)
        alert.layout()
        if let view = alert.window.contentView {
            write(capture(view), to: directory, name: "reset-alert")
        }
        report["alert.title"] = alert.messageText
        report["alert.message"] = alert.informativeText
        report["alert.buttons"] = alert.buttons
            .map { "\($0.title)[\($0.keyEquivalent.unicodeScalars.map { String($0.value) }.joined())]" }
            .joined(separator: ",")
        report["alert.defaultButton"] = alert.buttons
            .first { $0.cell === alert.window.defaultButtonCell }?.title ?? "none"

        // Return reaches an alert only while the app is active, which a
        // terminal-launched check is not; alert.defaultButton covers it instead.
        report["press.escape"] = press(keyCode: ResetConfirmation.escapeKeyCode, characters: "\u{1b}")

        let json = try? JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
        try? json?.write(to: directory.appendingPathComponent("report.json"))
    }

    /// Opens the real confirmation, sends one key, and reports what it decided.
    private static func press(keyCode: UInt16, characters: String) -> String {
        var timedOut = false
        let send = Timer(timeInterval: 0.5, repeats: false) { _ in
            MainActor.assumeIsolated {
                guard let event = NSEvent.keyEvent(
                    with: .keyDown, location: .zero, modifierFlags: [],
                    timestamp: ProcessInfo.processInfo.systemUptime,
                    windowNumber: NSApp.modalWindow?.windowNumber ?? 0, context: nil,
                    characters: characters, charactersIgnoringModifiers: characters,
                    isARepeat: false, keyCode: keyCode
                ) else { return }
                NSApp.postEvent(event, atStart: false)
            }
        }
        let timeout = Timer(timeInterval: 3, repeats: false) { _ in
            MainActor.assumeIsolated {
                timedOut = true
                NSApp.abortModal()
            }
        }
        RunLoop.main.add(send, forMode: .modalPanel)
        RunLoop.main.add(timeout, forMode: .modalPanel)
        let confirmed = ResetConfirmation.confirm(total: 1_876_491_418)
        send.invalidate()
        timeout.invalidate()
        if timedOut { return "timeout" }
        return confirmed ? "reset" : "cancel"
    }

    private static func snapshot(_ view: some View) -> Data? {
        let host = NSHostingView(rootView: view.background(Color(nsColor: .windowBackgroundColor)))
        host.frame.size = host.fittingSize
        let window = NSWindow(contentRect: host.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        return capture(host)
    }

    private static func capture(_ view: NSView) -> Data? {
        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return nil }
        view.cacheDisplay(in: view.bounds, to: rep)
        return rep.representation(using: .png, properties: [:])
    }

    private static func onWhite(_ image: NSImage) -> Data? {
        let canvas = NSImage(size: NSSize(width: image.size.width + 16, height: image.size.height + 8), flipped: false) { rect in
            NSColor.white.setFill()
            rect.fill()
            image.draw(in: NSRect(x: 8, y: 4, width: image.size.width, height: image.size.height))
            return true
        }
        guard let tiff = canvas.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }

    private static func write(_ data: Data?, to directory: URL, name: String) {
        try? data?.write(to: directory.appendingPathComponent("\(name).png"))
    }
}
#endif
