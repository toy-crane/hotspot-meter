import Testing
@testable import DataUsageCore

struct UsageTrackerTests {
    @Test func firstSampleOnlySetsBaseline() {
        var tracker = UsageTracker()
        let delta = tracker.record(interface: "en8", counters: ByteCounts(received: 5_000, sent: 1_000))
        #expect(delta == .zero)
    }

    @Test func countsGrowthSincePreviousSample() {
        var tracker = UsageTracker()
        _ = tracker.record(interface: "en8", counters: ByteCounts(received: 5_000, sent: 1_000))
        let delta = tracker.record(interface: "en8", counters: ByteCounts(received: 8_000, sent: 1_500))
        #expect(delta == ByteCounts(received: 3_000, sent: 500))
    }

    @Test func counterRestartCountsNewValueAsUsage() {
        var tracker = UsageTracker()
        _ = tracker.record(interface: "en8", counters: ByteCounts(received: 9_000, sent: 4_000))
        let delta = tracker.record(interface: "en8", counters: ByteCounts(received: 300, sent: 100))
        #expect(delta == ByteCounts(received: 300, sent: 100))
    }

    @Test func switchingInterfaceStartsNewBaseline() {
        var tracker = UsageTracker()
        _ = tracker.record(interface: "en8", counters: ByteCounts(received: 5_000, sent: 1_000))
        let delta = tracker.record(interface: "en0", counters: ByteCounts(received: 900_000, sent: 90_000))
        #expect(delta == .zero)
    }

    @Test func resetStartsNewBaseline() {
        var tracker = UsageTracker()
        _ = tracker.record(interface: "en8", counters: ByteCounts(received: 5_000, sent: 1_000))
        tracker.reset()
        let delta = tracker.record(interface: "en8", counters: ByteCounts(received: 7_000, sent: 2_000))
        #expect(delta == .zero)
    }

    @Test func countersAbove4GBDoNotWrap() {
        var tracker = UsageTracker()
        let fourGB: UInt64 = 4 * 1024 * 1024 * 1024
        _ = tracker.record(interface: "en8", counters: ByteCounts(received: fourGB - 100, sent: 0))
        let delta = tracker.record(interface: "en8", counters: ByteCounts(received: fourGB + 900, sent: 0))
        #expect(delta.received == 1_000)
    }
}

struct InterfaceCountersTests {
    @Test func readsLoopbackCounters() {
        #expect(InterfaceCounters.read(interface: "lo0") != nil)
    }
}
