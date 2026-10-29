import DataUsageCore
import SwiftUI

@main
struct DataUsageApp: App {
    @State private var model = UsageModel()

    var body: some Scene {
        MenuBarExtra {
            UsageView(model: model)
        } label: {
            Label {
                Text(model.total.total.formattedBytes)
            } icon: {
                Image(systemName: model.hotspotInterface == nil ? "personalhotspot.slash" : "personalhotspot")
            }
            .labelStyle(.titleAndIcon)
            .task { model.start() }
        }
        .menuBarExtraStyle(.window)
    }
}

struct UsageView: View {
    let model: UsageModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            status
            Divider()
            UsageRow(title: "이번 연결", counts: model.session)
            UsageRow(
                title: "누적 (\(model.totalSince.formatted(date: .abbreviated, time: .shortened))부터)",
                counts: model.total
            )
            Divider()
            HStack {
                Button("누적 초기화") { model.resetTotal() }
                Spacer()
                Button("종료") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding()
        .frame(width: 280)
    }

    @ViewBuilder private var status: some View {
        if let name = model.hotspotInterface {
            Label("핫스팟 연결됨 (\(name))", systemImage: "personalhotspot")
                .foregroundStyle(.green)
        } else {
            Label("핫스팟에 연결되어 있지 않음", systemImage: "personalhotspot.slash")
                .foregroundStyle(.secondary)
        }
    }
}

private struct UsageRow: View {
    let title: String
    let counts: ByteCounts

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(counts.total.formattedBytes)
                .font(.title2.monospacedDigit().bold())
            Text("↓ \(counts.received.formattedBytes)   ↑ \(counts.sent.formattedBytes)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}

extension UInt64 {
    var formattedBytes: String {
        ByteCountFormatter.string(fromByteCount: Int64(clamping: self), countStyle: .decimal)
    }
}
