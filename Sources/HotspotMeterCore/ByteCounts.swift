/// Received and sent byte totals for a network interface.
public struct ByteCounts: Equatable, Sendable {
    public var received: UInt64
    public var sent: UInt64

    public init(received: UInt64 = 0, sent: UInt64 = 0) {
        self.received = received
        self.sent = sent
    }

    public static let zero = ByteCounts()

    public var total: UInt64 { received + sent }

    public static func + (lhs: ByteCounts, rhs: ByteCounts) -> ByteCounts {
        ByteCounts(received: lhs.received + rhs.received, sent: lhs.sent + rhs.sent)
    }

    public static func += (lhs: inout ByteCounts, rhs: ByteCounts) {
        lhs = lhs + rhs
    }
}
