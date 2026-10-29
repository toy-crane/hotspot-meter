import DataUsageCore
import Foundation
import Observation

@MainActor
@Observable
final class UsageModel {
    /// Whether a hotspot connection is up and being counted.
    private(set) var isCounting = false
    /// Hotspot usage since the last reset.
    private(set) var total: UInt64
    private(set) var since: Date

    private var hotspotInterface: String?
    private var ledger: UsageLedger
    private var tracker = UsageTracker()
    private let monitor = HotspotMonitor()
    private var pollTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        let ledger = UsageLedger(defaults: defaults)
        self.ledger = ledger
        total = ledger.total
        since = ledger.since
    }

    func start() {
        guard pollTask == nil else { return }
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

    func reset() {
        ledger.reset()
        tracker.reset()
        sync()
    }

    private func hotspotChanged(to name: String?) {
        guard name != hotspotInterface else { return }
        hotspotInterface = name
        isCounting = name != nil
        tracker.reset()
        sample()
    }

    private func sample() {
        guard let name = hotspotInterface,
              let counters = InterfaceCounters.read(interface: name) else { return }
        let delta = tracker.record(interface: name, counters: counters)
        guard delta.total > 0 else { return }
        ledger.add(delta)
        sync()
    }

    private func sync() {
        total = ledger.total
        since = ledger.since
    }
}
