import SwiftUI

struct MonitorIcon: View {
    let kind: MonitorKind

    var body: some View {
        if let asset = kind.brandAsset {
            Image(asset).resizable().scaledToFit()
        } else {
            Image(systemName: kind.icon)
        }
    }
}

struct UsageBars: View {
    let snapshot: UsageSnapshot?
    let error: String?
    let kind: MonitorKind
    @AppStorage("usageDisplayMode", store: quotaSpaceDefaults)
    private var usageDisplayMode = UsageDisplayMode.remaining

    var body: some View {
        if let snapshot {
            VStack(spacing: 10) {
                if snapshot.isStale {
                    Label("Disconnected", systemImage: "wifi.slash")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
                if let value = snapshot.sessionRemaining {
                    UsageBar(
                        title: snapshot.weeklyRemaining == nil ? "Available" : "5-hour",
                        value: value,
                        reset: snapshot.sessionReset,
                        kind: kind,
                        mode: usageDisplayMode
                    )
                }
                if let value = snapshot.weeklyRemaining {
                    UsageBar(
                        title: "Weekly",
                        value: value,
                        reset: snapshot.weeklyReset,
                        kind: kind,
                        mode: usageDisplayMode
                    )
                }
                if snapshot.tightestRemaining == nil {
                    Text(error ?? "No cached usage yet. Open this Claude profile, then refresh.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            Text(error ?? "Waiting for the first refresh…")
                .font(.caption)
                .foregroundStyle(error == nil ? Color.secondary : Color.red)
                .lineLimit(2)
        }
    }
}

private struct UsageBar: View {
    let title: String
    let value: Int
    let reset: Date?
    let kind: MonitorKind
    let mode: UsageDisplayMode

    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text(title)
                Spacer()
                if let reset {
                    Text("resets \(reset, style: .relative)").foregroundStyle(.secondary)
                }
                Text("\(mode.percent(fromRemaining: value))% \(suffix)").monospacedDigit()
            }
            .font(.caption)
            ProgressView(value: Double(mode.percent(fromRemaining: value)), total: 100)
                .tint(value < 20 ? .red : value < 40 ? .orange : .accentColor)
        }
    }

    private var suffix: String {
        mode == .used ? "used" : kind == .disk ? "free" : "left"
    }
}
