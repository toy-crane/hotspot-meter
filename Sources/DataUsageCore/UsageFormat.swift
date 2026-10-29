import Foundation

/// Text shown for usage amounts and dates in the menu bar and panel.
public enum UsageFormat {
    /// Formats a byte count in decimal units, as carriers count data.
    public static func bytes(_ count: UInt64) -> String {
        let value = Double(count)
        // Pick the unit from the rounded value so 999,600 bytes reads "1.0 MB", not "1000 KB".
        let kilobytes = (value / 1e3).rounded()
        let megabytes = (value / 1e5).rounded() / 10
        switch count {
        case 0: return "0 KB"
        case ..<1_000: return "\(count) bytes"
        default:
            if kilobytes < 1_000 { return "\(Int(kilobytes)) KB" }
            if megabytes < 1_000 { return String(format: "%.1f MB", megabytes) }
            return String(format: "%.2f GB", value / 1e9)
        }
    }

    /// The start date shown above the total, such as "10월 27일부터".
    public static func since(_ date: Date) -> String {
        formatter("M월 d일").string(from: date) + "부터"
    }

    /// The start date and time shown on hover, such as "10월 27일 오후 9:14".
    public static func sinceDetail(_ date: Date) -> String {
        formatter("M월 d일 a h:mm").string(from: date)
    }

    private static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = format
        return formatter
    }
}
