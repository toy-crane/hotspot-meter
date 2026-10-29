import AppKit
import SwiftUI

@main
struct HotspotMeterApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var model = UsageModel()

    var body: some Scene {
        MenuBarExtra {
            UsagePanel(
                total: model.total,
                since: model.since,
                isCounting: model.isCounting,
                onReset: {
                    if ResetConfirmation.confirm(total: model.total) {
                        model.reset()
                    }
                },
                onQuit: { NSApp.terminate(nil) }
            )
        } label: {
            Image(nsImage: MenuBarLabel.image(total: model.total, isCounting: model.isCounting))
                .task { model.start() }
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        LaunchAtLogin.registerOnce()
        #if DEBUG
        SelfCheck.runIfRequested()
        #endif
    }
}
