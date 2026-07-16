import SwiftUI

struct AccountsView: View {
    @EnvironmentObject private var store: MonitorStore

    var body: some View {
        Form {
            Section {
                ForEach(store.items.filter { $0.kind != .disk }) { item in
                    EditableItemRow(item: item, showDestinations: false)
                }
            } header: {
                Text("Connected accounts")
            } footer: {
                Text("Claude follows the account currently active in Claude Code. Switching accounts is reflected on the next refresh.")
            }
            Button("Refresh Accounts", systemImage: "arrow.clockwise") { store.rescan() }
        }
        .formStyle(.grouped)
        .navigationTitle("Accounts")
    }
}

struct DisplaySettingsView: View {
    @EnvironmentObject private var store: MonitorStore

    var body: some View {
        Form {
            Section("Menu Bar & Widget") {
                ForEach(store.items) { item in
                    EditableItemRow(item: item, showDestinations: true)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Display")
    }
}

private struct EditableItemRow: View {
    @EnvironmentObject private var store: MonitorStore
    let item: MonitorItem
    let showDestinations: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.kind.icon).frame(width: 24)
            TextField("Name", text: binding(\.name)).textFieldStyle(.plain).frame(minWidth: 100)
            Spacer()
            if showDestinations {
                Toggle("Menu Bar", isOn: binding(\.showInMenuBar)).toggleStyle(.switch)
                Toggle("Widget", isOn: binding(\.showInWidget)).toggleStyle(.switch)
            } else {
                Toggle("Monitor", isOn: binding(\.isEnabled)).toggleStyle(.switch)
            }
        }
        .padding(.vertical, 4)
    }

    private func binding<T>(_ keyPath: WritableKeyPath<MonitorItem, T>) -> Binding<T> {
        Binding(get: { item[keyPath: keyPath] }, set: { value in
            var copy = item
            copy[keyPath: keyPath] = value
            store.update(copy)
        })
    }
}
