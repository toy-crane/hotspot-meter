import AppKit
import HotspotMeterCore

/// Asks before clearing the total, with Cancel as the default for Return and Escape.
@MainActor
enum ResetConfirmation {
    static func makeAlert(total: UInt64) -> NSAlert {
        let alert = NSAlert()
        alert.messageText = "사용량을 초기화할까요?"
        alert.informativeText = "\(UsageFormat.bytes(total)) 기록이 사라집니다."
        let cancel = alert.addButton(withTitle: "취소")
        let reset = alert.addButton(withTitle: "초기화")
        cancel.keyEquivalent = "\r"
        reset.keyEquivalent = ""
        return alert
    }

    /// Returns true only when the user clicks 초기화.
    static func confirm(total: UInt64) -> Bool {
        NSApp.activate()
        let alert = makeAlert(total: total)
        // NSAlert maps Escape only to a button titled "Cancel" in English,
        // so stop the modal session ourselves.
        let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard event.keyCode == escapeKeyCode else { return event }
            NSApp.abortModal()
            return nil
        }
        defer { monitor.map(NSEvent.removeMonitor) }
        return alert.runModal() == .alertSecondButtonReturn
    }

    static let escapeKeyCode: UInt16 = 53
}
