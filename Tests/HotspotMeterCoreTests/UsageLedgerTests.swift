import Foundation
import Testing
@testable import HotspotMeterCore

struct UsageLedgerTests {
    private let defaults: UserDefaults
    private let started = Date(timeIntervalSince1970: 1_793_000_000)

    init() throws {
        defaults = try #require(UserDefaults(suiteName: "UsageLedgerTests.\(UUID().uuidString)"))
    }

    @Test func totalAndStartSurviveRelaunch() {
        var ledger = UsageLedger(defaults: defaults, now: started)
        ledger.add(ByteCounts(received: 6_000_000_000, sent: 1_000))
        ledger.add(ByteCounts(received: 500, sent: 2_000))

        let relaunched = UsageLedger(defaults: defaults, now: started.addingTimeInterval(86_400))
        #expect(relaunched.total == 6_000_003_500)
        #expect(relaunched.since == started)
    }

    @Test func resetStartsCountingFromZeroAtResetTime() {
        var ledger = UsageLedger(defaults: defaults, now: started)
        ledger.add(ByteCounts(received: 1_876_491_418, sent: 0))
        let resetAt = started.addingTimeInterval(3_600)
        ledger.reset(at: resetAt)

        #expect(ledger.total == 0)
        #expect(ledger.since == resetAt)
        let relaunched = UsageLedger(defaults: defaults, now: started.addingTimeInterval(86_400))
        #expect(relaunched.total == 0)
        #expect(relaunched.since == resetAt)
    }
}
