import Foundation

/// Hotspot usage counted since the last reset, kept across relaunches.
public struct UsageLedger {
    public private(set) var total: UInt64
    public private(set) var since: Date

    private let defaults: UserDefaults

    private enum Key {
        static let total = "ledger.total"
        static let since = "ledger.since"
    }

    public init(defaults: UserDefaults = .standard, now: Date = .now) {
        self.defaults = defaults
        total = UInt64(max(0, defaults.integer(forKey: Key.total)))
        since = defaults.object(forKey: Key.since) as? Date ?? now
        save()
    }

    public mutating func add(_ delta: ByteCounts) {
        total += delta.total
        save()
    }

    public mutating func reset(at date: Date = .now) {
        total = 0
        since = date
        save()
    }

    private func save() {
        defaults.set(Int(clamping: total), forKey: Key.total)
        defaults.set(since, forKey: Key.since)
    }
}
