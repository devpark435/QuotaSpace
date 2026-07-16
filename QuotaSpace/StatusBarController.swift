import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    static let shared = StatusBarController()

    private var statusItems: [String: NSStatusItem] = [:]
    private let popover = NSPopover()
    private var observer: NSObjectProtocol?

    func start() {
        popover.behavior = .transient
        observer = NotificationCenter.default.addObserver(forName: .monitorStoreChanged, object: nil, queue: .main) { _ in
            Task { @MainActor in self.sync() }
        }
        sync()
    }

    private func sync() {
        let store = MonitorStore.shared
        let visible = store.items.filter { $0.isEnabled && $0.showInMenuBar }
        let visibleIDs = Set(visible.map(\.id))

        for (id, item) in statusItems where !visibleIDs.contains(id) {
            NSStatusBar.system.removeStatusItem(item)
            statusItems[id] = nil
        }

        for item in visible {
            let statusItem = statusItems[item.id] ?? makeStatusItem(for: item)
            let remaining = store.snapshots[item.id]?.tightestRemaining
            let mode = UsageDisplayMode.current
            statusItem.button?.image = item.kind.brandAsset.flatMap { NSImage(named: $0) }
                ?? NSImage(systemSymbolName: item.kind.icon, accessibilityDescription: item.name)
            statusItem.button?.image?.isTemplate = true
            statusItem.button?.image?.size = NSSize(width: 16, height: 16)
            statusItem.button?.title = " \(remaining.map { "\(mode.percent(fromRemaining: $0))%" } ?? "—")"
            statusItem.button?.toolTip = "\(item.name) \(mode == .remaining ? "remaining" : "used")"
        }
    }

    private func makeStatusItem(for item: MonitorItem) -> NSStatusItem {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.identifier = NSUserInterfaceItemIdentifier(item.id)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(showDetail(_:))
        statusItems[item.id] = statusItem
        return statusItem
    }

    @objc private func showDetail(_ sender: NSStatusBarButton) {
        let id = sender.identifier?.rawValue ?? ""
        popover.contentViewController = NSHostingController(
            rootView: StatusDetailView(itemID: id) { [weak self] in
                self?.popover.performClose(nil)
            }
            .environmentObject(MonitorStore.shared)
        )
        popover.contentSize = NSSize(width: 320, height: 240)
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    }
}

struct StatusDetailView: View {
    @EnvironmentObject private var store: MonitorStore
    let itemID: String
    let dismiss: () -> Void
    @AppStorage("usageDisplayMode", store: quotaSpaceDefaults)
    private var usageDisplayMode = UsageDisplayMode.remaining

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(perform: dismiss)
            VStack(alignment: .leading, spacing: 16) {
                if let item = store.items.first(where: { $0.id == itemID }) {
                    HStack {
                        MonitorIcon(kind: item.kind)
                            .frame(width: 24, height: 24)
                        Text(item.name)
                            .font(.headline)
                        Spacer()
                        Text(store.snapshots[item.id]?.tightestRemaining.map {
                            "\(usageDisplayMode.percent(fromRemaining: $0))%"
                        } ?? "—")
                            .font(.title.bold())
                            .monospacedDigit()
                    }
                    UsageBars(
                        snapshot: store.snapshots[item.id],
                        error: store.errors[item.id],
                        kind: item.kind
                    )
                    Spacer()
                    HStack {
                        Button("Open QuotaSpace") {
                            dismiss()
                            NSApp.activate(ignoringOtherApps: true)
                            NSApp.windows.first { $0.canBecomeMain }?.makeKeyAndOrderFront(nil)
                        }
                        .buttonStyle(.glass)
                        Spacer()
                        Button("Refresh") { Task { await store.refresh() } }.buttonStyle(.glass)
                    }
                }
            }
        }
        .padding(18)
    }
}
