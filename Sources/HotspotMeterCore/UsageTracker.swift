/// Turns cumulative interface counters into usage deltas.
///
/// Interface counters only ever grow until the interface is recreated
/// (for example when an iPhone USB cable is unplugged and reconnected),
/// at which point they restart from zero. The tracker treats a counter
/// that went backwards as a fresh start and counts its new value as usage.
public struct UsageTracker: Sendable {
    private var lastInterface: String?
    private var lastCounters: ByteCounts?

    public init() {}

    /// Records a counter sample and returns the bytes used since the previous sample.
    ///
    /// The first sample for an interface only sets the baseline and returns zero.
    public mutating func record(interface: String, counters: ByteCounts) -> ByteCounts {
        defer {
            lastInterface = interface
            lastCounters = counters
        }
        guard interface == lastInterface, let last = lastCounters else {
            return .zero
        }
        return ByteCounts(
            received: Self.delta(from: last.received, to: counters.received),
            sent: Self.delta(from: last.sent, to: counters.sent)
        )
    }

    /// Forgets the baseline so the next sample starts a new measurement.
    public mutating func reset() {
        lastInterface = nil
        lastCounters = nil
    }

    private static func delta(from last: UInt64, to current: UInt64) -> UInt64 {
        current >= last ? current - last : current
    }
}
