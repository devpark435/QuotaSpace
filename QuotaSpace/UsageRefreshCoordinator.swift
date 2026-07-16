import Foundation

final class UsageRefreshCoordinator: @unchecked Sendable {
    static let shared = UsageRefreshCoordinator()

    private let queue = DispatchQueue(label: "QuotaSpace.usage-events")
    private var activityTimer: DispatchSourceTimer?
    private var pendingRefresh: DispatchWorkItem?
    private var fallbackTimer: DispatchSourceTimer?

    func start(home: URL = FileManager.default.homeDirectoryForCurrentUser) {
        queue.async {
            let paths = [
                home.appendingPathComponent(".claude/projects"),
                home.appendingPathComponent(".codex/sessions"),
            ]
            var signature = Self.activitySignature(paths)
            let activityTimer = DispatchSource.makeTimerSource(queue: self.queue)
            activityTimer.schedule(deadline: .now() + .seconds(2), repeating: .seconds(2))
            activityTimer.setEventHandler {
                let next = Self.activitySignature(paths)
                guard next != signature else { return }
                signature = next
                self.scheduleRefresh()
            }
            activityTimer.resume()
            self.activityTimer = activityTimer

            let timer = DispatchSource.makeTimerSource(queue: self.queue)
            timer.schedule(deadline: .now() + .seconds(600), repeating: .seconds(600))
            timer.setEventHandler { self.refresh() }
            timer.resume()
            self.fallbackTimer = timer
        }
    }

    func stop() {
        queue.async {
            self.pendingRefresh?.cancel()
            self.activityTimer?.cancel()
            self.activityTimer = nil
            self.fallbackTimer?.cancel()
            self.fallbackTimer = nil
        }
    }

    private func scheduleRefresh() {
        pendingRefresh?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.refresh() }
        pendingRefresh = work
        queue.asyncAfter(deadline: .now() + 2, execute: work)
    }

    private func refresh() {
        Task { @MainActor in await MonitorStore.shared.refresh() }
    }

    private static func activitySignature(_ roots: [URL]) -> String {
        var count = 0
        var latest = 0.0
        for root in roots {
            let files = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsPackageDescendants]
            )?.compactMap { $0 as? URL } ?? []
            for file in files where file.pathExtension == "jsonl" {
                count += 1
                let date = try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                latest = max(latest, date?.timeIntervalSinceReferenceDate ?? 0)
            }
        }
        return "\(count):\(latest)"
    }
}
