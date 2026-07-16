import SwiftUI
import WidgetKit

struct AccountsView: View {
    @EnvironmentObject private var store: MonitorStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PageHeader(
                    title: "Accounts",
                    subtitle: "Choose which connected services QuotaSpace monitors."
                )

                VStack(spacing: 0) {
                    ForEach(Array(store.items.filter { $0.kind != .disk }.enumerated()), id: \.element.id) { index, item in
                        AccountRow(
                            item: item,
                            snapshot: store.snapshots[item.id],
                            error: store.errors[item.id]
                        )
                        if index < store.items.filter({ $0.kind != .disk }).count - 1 {
                            Divider().padding(.leading, 70)
                        }
                    }
                }
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))

                Text("Claude follows the account currently active in Claude Code.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Scan Accounts", systemImage: "arrow.clockwise") {
                    store.rescan()
                    Task { await store.refresh() }
                }
                .buttonStyle(.glass)
            }
            .padding(28)
        }
        .navigationTitle("Accounts")
    }
}

struct DisplaySettingsView: View {
    @EnvironmentObject private var store: MonitorStore
    @AppStorage("usageDisplayMode", store: quotaSpaceDefaults)
    private var usageDisplayMode = UsageDisplayMode.remaining

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PageHeader(
                    title: "Display",
                    subtitle: "Control how usage and status items appear."
                )

                VStack(alignment: .leading, spacing: 14) {
                    Text("Usage")
                        .font(.headline)
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Show usage as")
                            Text("The number and progress bar always use the same meaning.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Picker("Show usage as", selection: $usageDisplayMode) {
                            ForEach(UsageDisplayMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .frame(width: 220)
                    }
                }
                .padding(18)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))

                VStack(alignment: .leading, spacing: 0) {
                    Text("Visible in")
                        .font(.headline)
                        .padding(.horizontal, 18)
                        .padding(.top, 18)
                        .padding(.bottom, 8)

                    ForEach(Array(store.items.enumerated()), id: \.element.id) { index, item in
                        DisplayRow(item: item)
                        if index < store.items.count - 1 {
                            Divider().padding(.leading, 70)
                        }
                    }
                }
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
            }
            .padding(28)
        }
        .onChange(of: usageDisplayMode) {
            NotificationCenter.default.post(name: .monitorStoreChanged, object: nil)
            WidgetCenter.shared.reloadAllTimelines()
        }
        .navigationTitle("Display")
    }
}

private struct PageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.largeTitle.bold())
            Text(subtitle).foregroundStyle(.secondary)
        }
    }
}

private struct AccountRow: View {
    @EnvironmentObject private var store: MonitorStore
    let item: MonitorItem
    let snapshot: UsageSnapshot?
    let error: String?

    var body: some View {
        HStack(spacing: 14) {
            MonitorIcon(kind: item.kind)
                .frame(width: 22, height: 22)
                .frame(width: 42, height: 42)
                .glassEffect(.clear, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name).font(.headline)
                Text(item.kind == .claude ? "Current Claude Code account" : "Local Codex account")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            connectionStatus
            Toggle("Monitor", isOn: binding(\.isEnabled))
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding(16)
    }

    @ViewBuilder
    private var connectionStatus: some View {
        if snapshot?.isStale == true || snapshot == nil && error != nil {
            Label("Disconnected", systemImage: "wifi.slash")
                .foregroundStyle(.orange)
        } else if snapshot != nil {
            Label("Connected", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } else {
            ProgressView().controlSize(.small)
        }
    }

    private func binding<T>(_ keyPath: WritableKeyPath<MonitorItem, T>) -> Binding<T> {
        Binding(get: { item[keyPath: keyPath] }, set: { value in
            var copy = item
            copy[keyPath: keyPath] = value
            store.update(copy)
        })
    }
}

private struct DisplayRow: View {
    @EnvironmentObject private var store: MonitorStore
    let item: MonitorItem

    var body: some View {
        HStack(spacing: 14) {
            MonitorIcon(kind: item.kind)
                .frame(width: 20, height: 20)
                .frame(width: 38, height: 38)
                .glassEffect(.clear, in: Circle())
            TextField("Name", text: binding(\.name))
                .textFieldStyle(.plain)
            Spacer()
            Toggle("Menu Bar", isOn: binding(\.showInMenuBar))
                .toggleStyle(.switch)
            Toggle("Widget", isOn: binding(\.showInWidget))
                .toggleStyle(.switch)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func binding<T>(_ keyPath: WritableKeyPath<MonitorItem, T>) -> Binding<T> {
        Binding(get: { item[keyPath: keyPath] }, set: { value in
            var copy = item
            copy[keyPath: keyPath] = value
            store.update(copy)
        })
    }
}
