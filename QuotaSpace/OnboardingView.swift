import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: MonitorStore
    @Binding var completedOnboarding: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "circle.grid.2x2.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(.tint)
                Text("Welcome to QuotaSpace").font(.largeTitle.bold())
                Text("Choose the accounts and system information you want to monitor.")
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                ForEach(store.items) { item in OnboardingRow(item: item) }
            }

            HStack {
                Button("Scan Again", systemImage: "arrow.clockwise") { store.rescan() }.buttonStyle(.glass)
                Spacer()
                Button("Start Monitoring") {
                    completedOnboarding = true
                    Task { await store.refresh() }
                }
                .buttonStyle(.glassProminent)
            }
        }
        .padding(36)
        .frame(minWidth: 680, minHeight: 500)
    }
}

private struct OnboardingRow: View {
    @EnvironmentObject private var store: MonitorStore
    let item: MonitorItem

    var body: some View {
        HStack(spacing: 14) {
            MonitorIcon(kind: item.kind)
                .font(.title2)
                .frame(width: 20, height: 20)
                .frame(width: 38, height: 38)
                .glassEffect(.clear, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.headline)
                Text(item.source.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("Monitor", isOn: enabledBinding).toggleStyle(.switch).labelsHidden()
        }
        .padding(14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
    }

    private var enabledBinding: Binding<Bool> {
        Binding(get: { item.isEnabled }, set: { value in
            var copy = item
            copy.isEnabled = value
            store.update(copy)
        })
    }
}
