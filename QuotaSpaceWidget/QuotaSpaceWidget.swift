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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("QuotaSpace", systemImage: "circle.grid.2x2.fill")
                    .font(.headline)
                Spacer()
                Text("\(entry.disk.availablePercent)%")
                    .font(.title2.bold())
                    .contentTransition(.numericText())
            }

            ProgressView(value: entry.disk.availableFraction)
                .tint(.blue)

            Text("\(entry.disk.availableText) disk space available")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            HStack {
                Label("Claude", systemImage: "sparkles")
                Spacer()
                Label("Codex", systemImage: "chevron.left.forwardslash.chevron.right")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .containerBackground(.clear, for: .widget)
    }
}

struct QuotaSpaceWidget: Widget {
    let kind = "QuotaSpaceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CapacityProvider()) { entry in
            QuotaSpaceWidgetView(entry: entry)
        }
        .configurationDisplayName("QuotaSpace")
        .description("See your AI quotas and Mac storage at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct QuotaSpaceWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuotaSpaceWidget()
    }
}

