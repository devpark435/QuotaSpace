import Combine
import Foundation

@MainActor
final class MonitorStore: ObservableObject {
    static let shared = MonitorStore()

    @Published var items: [MonitorItem]
    @Published var snapshots: [String: UsageSnapshot]
    @Published var errors: [String: String] = [:]
    @Published var isRefreshing = false

    private let defaults = UserDefaults.standard
    private var failureCounts: [String: Int] = [:]

    private init() {
        UserDefaults.standard.removeObject(forKey: "claudeTokenEmails")
        items = Self.decode([MonitorItem].self, from: UserDefaults.standard.data(forKey: "monitorItems")) ?? []
        snapshots = Self.decode([String: UsageSnapshot].self, from: UserDefaults.standard.data(forKey: "usageSnapshots")) ?? [:]
        for id in snapshots.keys where id.hasPrefix("claude:") {
            snapshots[id]?.detail = "Claude"
        }
        if items.isEmpty {
            items = AccountDiscovery.discover()
        } else {
            rescan()
        }
    }

    func rescan() {
        let existing = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        items = AccountDiscovery.discover().map { found in
            guard let saved = existing[found.id] else { return found }
            var merged = found
            merged.name = saved.name
            merged.isEnabled = saved.isEnabled
            merged.showInMenuBar = saved.showInMenuBar
            merged.showInWidget = saved.showInWidget
            return merged
        }
        save()
    }

    func update(_ item: MonitorItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
        save()
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false; save() }

        for item in items where item.isEnabled {
            do {
                let snapshot: UsageSnapshot
                switch item.kind {
                case .disk:
                    let disk = try DiskCapacity.current()
                    snapshot = UsageSnapshot(
                        sessionRemaining: disk.availablePercent,
                        weeklyRemaining: nil,
                        detail: "\(disk.availableText) free of \(disk.totalText)"
                    )
                case .claude:
                    snapshot = try await ClaudeUsageFetcher.fetch()
                case .codex:
                    snapshot = try await CodexUsageFetcher.fetch()
                }
                snapshots[item.id] = snapshot
                errors[item.id] = nil
                failureCounts[item.id] = 0
            } catch {
                errors[item.id] = error.localizedDescription
                if case .rateLimited? = error as? UsageFetchError {
                    failureCounts[item.id] = 0
                    snapshots[item.id]?.staleSince = nil
                } else if snapshots[item.id] != nil {
                    failureCounts[item.id, default: 0] += 1
                    snapshots[item.id]?.staleSince = failureCounts[item.id, default: 0] >= 3 ? Date() : nil
                }
            }
        }
    }

    private func save() {
        defaults.set(try? JSONEncoder().encode(items), forKey: "monitorItems")
        defaults.set(try? JSONEncoder().encode(snapshots), forKey: "usageSnapshots")
        NotificationCenter.default.post(name: .monitorStoreChanged, object: nil)
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        data.flatMap { try? JSONDecoder().decode(type, from: $0) }
    }
}
