import SwiftUI
import WidgetKit

struct CapacityEntry: TimelineEntry {
    let date: Date
    let disk: DiskCapacity
}

struct CapacityProvider: TimelineProvider {
    func placeholder(in context: Context) -> CapacityEntry {
        CapacityEntry(date: .now, disk: DiskCapacity(available: 180_000_000_000, total: 500_000_000_000))
    }

    func getSnapshot(in context: Context, completion: @escaping (CapacityEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CapacityEntry>) -> Void) {
        let entry = entry()
        completion(Timeline(entries: [entry], policy: .after(entry.date.addingTimeInterval(15 * 60))))
    }

    private func entry() -> CapacityEntry {
        CapacityEntry(date: .now, disk: (try? DiskCapacity.current()) ?? .unavailable)
    }
}

struct QuotaSpaceWidgetView: View {
    let entry: CapacityEntry
    @AppStorage("usageDisplayMode", store: quotaSpaceDefaults)
    private var usageDisplayMode = UsageDisplayMode.remaining

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Mac Storage", systemImage: "internaldrive.fill")
                    .font(.headline)
                Spacer()
            }

            Spacer(minLength: 0)

            Text("\(usageDisplayMode.percent(fromRemaining: entry.disk.availablePercent))%")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .contentTransition(.numericText())

            Text(usageDisplayMode == .remaining ? "available" : "used")
                .font(.caption)
                .foregroundStyle(.secondary)

            ProgressView(
                value: usageDisplayMode == .remaining
                    ? entry.disk.availableFraction
                    : 1 - entry.disk.availableFraction
            )
                .tint(.blue)

            Text(
                "\(usageDisplayMode == .remaining ? entry.disk.availableText : entry.disk.usedText) "
                    + "\(usageDisplayMode == .remaining ? "free" : "used") of \(entry.disk.totalText)"
            )
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct QuotaSpaceWidget: Widget {
    let kind = "QuotaSpaceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CapacityProvider()) { entry in
            QuotaSpaceWidgetView(entry: entry)
        }
        .configurationDisplayName("QuotaSpace")
        .description("See available Mac storage at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct QuotaSpaceWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuotaSpaceWidget()
    }
}
