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

    var body: some View {
        if let snapshot {
            VStack(spacing: 10) {
                if snapshot.isStale {
                    Label("Stale", systemImage: "clock.badge.exclamationmark")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
                if let value = snapshot.sessionRemaining {
                    UsageBar(
                        title: snapshot.weeklyRemaining == nil ? "Available" : "5-hour",
                        value: value,
                        reset: snapshot.sessionReset
                    )
                }
                if let value = snapshot.weeklyRemaining {
                    UsageBar(title: "Weekly", value: value, reset: snapshot.weeklyReset)
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

    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text(title)
                Spacer()
                if let reset {
                    Text("resets \(reset, style: .relative)").foregroundStyle(.secondary)
                }
                Text("\(value)% left").monospacedDigit()
            }
            .font(.caption)
            ProgressView(value: Double(value), total: 100)
                .tint(value < 20 ? .red : value < 40 ? .orange : .accentColor)
        }
    }
}
