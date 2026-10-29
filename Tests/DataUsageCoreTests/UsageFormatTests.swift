import Foundation
import Testing
@testable import DataUsageCore

struct UsageFormatTests {
    @Test(arguments: [
        (UInt64(0), "0 KB"),
        (512, "512 bytes"),
        (12_345, "12 KB"),
        (342_722_908, "342.7 MB"),
        (1_876_491_418, "1.88 GB"),
    ])
    func bytesUseDecimalUnits(bytes: UInt64, expected: String) {
        #expect(UsageFormat.bytes(bytes) == expected)
    }

    @Test func sinceShowsDateAndTooltipShowsTime() throws {
        let date = try #require(Calendar.current.date(
            from: DateComponents(year: 2026, month: 10, day: 27, hour: 21, minute: 14)
        ))
        #expect(UsageFormat.since(date) == "10월 27일부터")
        #expect(UsageFormat.sinceDetail(date) == "10월 27일 오후 9:14")
    }
}
