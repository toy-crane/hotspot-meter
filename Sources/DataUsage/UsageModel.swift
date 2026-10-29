import DataUsageCore
import Foundation
import Observation

@MainActor
@Observable
final class UsageModel {
    /// Interface carrying the hotspot connection, such as `en8` for iPhone USB.
    private(set) var hotspotInterface: String?
    /// Usage since the current hotspot connection started.
    private(set) var session = ByteCounts.zero
    /// Usage on hotspot connections since the last manual reset.
    private(set) var total: ByteCounts
    private(set) var totalSince: Date

    private var tracker = UsageTracker()
    private let monitor = HotspotMonitor()
    private let defaults: UserDefaults
    private var pollTask: Task<Void, Never>?

    private enum Key {
        static let received = "total.received"
        static let sent = "total.sent"
        static let since = "total.since"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        total = ByteCounts(
            received: UInt64(defaults.integer(forKey: Key.received)),
            sent: UInt64(defaults.integer(forKey: Key.sent))
        )
        totalSince = defaults.object(forKey: Key.since) as? Date ?? .now
        defaults.set(totalSince, forKey: Key.since)
    }

    func start() {
        monitor.start { [weak self] name in
            self?.hotspotChanged(to: name)
        }
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.sample()
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    func resetTotal() {
        total = .zero
        totalSince = .now
        save()
    }

    private func hotspotChanged(to name: String?) {
        guard name != hotspotInterface else { return }
        hotspotInterface = name
        tracker.reset()
        if name != nil {
            session = .zero
        }
        sample()
    }

    private func sample() {
        guard let name = hotspotInterface,
              let counters = InterfaceCounters.read(interface: name) else { return }
        let delta = tracker.record(interface: name, counters: counters)
        guard delta.total > 0 else { return }
        session += delta
        total += delta
        save()
    }

    private func save() {
        defaults.set(Int(clamping: total.received), forKey: Key.received)
        defaults.set(Int(clamping: total.sent), forKey: Key.sent)
        defaults.set(totalSince, forKey: Key.since)
    }
}
