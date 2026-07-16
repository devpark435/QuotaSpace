import AppKit
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: MonitorStore
    @State private var selection = Section.overview

    enum Section: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case accounts = "Accounts"
        case display = "Display"
        var id: Self { self }
        var icon: String {
            switch self {
            case .overview: "rectangle.grid.1x2"
            case .accounts: "person.2"
            case .display: "menubar.rectangle"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(Section.allCases, selection: $selection) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
            .navigationTitle("QuotaSpace")
            .frame(minWidth: 180)
        } detail: {
            Group {
                switch selection {
                case .overview: OverviewView()
                case .accounts: AccountsView()
                case .display: DisplaySettingsView()
                }
            }
            .environmentObject(store)
        }
        .toolbar {
            ToolbarItem {
                Button("Refresh", systemImage: "arrow.clockwise") {
                    Task { await store.refresh() }
                }
                .disabled(store.isRefreshing)
            }
        }
        .task { await store.refresh() }
    }
}

private struct OverviewView: View {
    @EnvironmentObject private var store: MonitorStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overview")
                        .font(.largeTitle.bold())
                    Text(store.isRefreshing ? "Refreshing…" : "Claude, Codex, and Mac capacity")
                        .foregroundStyle(.secondary)
                }

                GlassEffectContainer(spacing: 14) {
                    LazyVStack(spacing: 14) {
                        ForEach(store.items.filter(\.isEnabled)) { item in
                            UsageCard(
                                item: item,
                                snapshot: store.snapshots[item.id],
                                error: store.errors[item.id]
                            )
                        }
                    }
                }
            }
            .padding(28)
        }
        .navigationTitle("Overview")
    }
}

private struct UsageCard: View {
    let item: MonitorItem
    let snapshot: UsageSnapshot?
    let error: String?
    @AppStorage("usageDisplayMode", store: quotaSpaceDefaults)
    private var usageDisplayMode = UsageDisplayMode.remaining

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                MonitorIcon(kind: item.kind)
                    .font(.title2)
                    .foregroundStyle(tint)
                    .frame(width: 24, height: 24)
                    .frame(width: 44, height: 44)
                    .glassEffect(.clear, in: Circle())
                Text(item.name)
                    .font(.headline)
                Spacer()
                Text(snapshot?.tightestRemaining.map(displayText) ?? "—")
                    .font(.title3.bold())
                    .contentTransition(.numericText())
            }
            UsageBars(snapshot: snapshot, error: error, kind: item.kind)
            if item.kind == .disk, let detail = snapshot?.detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    private var tint: Color {
        switch item.kind {
        case .claude: .orange
        case .codex: .green
        case .disk: .blue
        }
    }

    private func displayText(_ remaining: Int) -> String {
        let suffix = usageDisplayMode == .used ? "used" : item.kind == .disk ? "free" : "left"
        return "\(usageDisplayMode.percent(fromRemaining: remaining))% \(suffix)"
    }
}
