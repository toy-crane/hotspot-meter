import Foundation
import OSLog
import ServiceManagement

/// Adds the app to login items once, so counting resumes after a restart.
///
/// Registration runs only on the first launch; if the user later turns the
/// login item off in System Settings, the app respects that choice.
enum LaunchAtLogin {
    private static let registeredKey = "launchAtLogin.registered"
    private static let logger = Logger(subsystem: "com.toycrane.DataUsage", category: "LaunchAtLogin")

    static func registerOnce(defaults: UserDefaults = .standard) {
        guard Bundle.main.bundleURL.pathExtension == "app",
              !defaults.bool(forKey: registeredKey) else { return }
        do {
            try SMAppService.mainApp.register()
            defaults.set(true, forKey: registeredKey)
        } catch {
            logger.error("Login item registration failed: \(error.localizedDescription)")
        }
    }
}
