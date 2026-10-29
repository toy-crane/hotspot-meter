import DataUsageCore
import SwiftUI

/// The window that opens from the menu bar item.
struct UsagePanel: View {
    let total: UInt64
    let since: Date
    let isCounting: Bool
    let onReset: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(UsageFormat.since(since))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .help(UsageFormat.sinceDetail(since))
            HStack(alignment: .center) {
                Text(UsageFormat.bytes(total))
                    .font(.system(size: 30, weight: .bold))
                    .monospacedDigit()
                Spacer(minLength: 8)
                CountingBadge(isCounting: isCounting)
            }
            Divider()
                .padding(.top, 14)
                .padding(.bottom, 12)
            HStack {
                Button("초기화", action: onReset)
                Spacer()
                Button("종료", action: onQuit)
            }
        }
        .padding(16)
        .frame(width: 280)
    }
}

private struct CountingBadge: View {
    let isCounting: Bool

    var body: some View {
        let color: Color = isCounting ? .green : .secondary
        HStack(spacing: 5) {
            Circle()
                .frame(width: 6, height: 6)
            Text(isCounting ? "집계 중" : "핫스팟 아님")
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(color.opacity(0.12), in: Capsule())
    }
}
