import Foundation

enum MonitorKind: String, Codable, Sendable {
    case claude, codex, disk

    var icon: String {
        switch self {
        case .claude: "sparkles"
        case .codex: "chevron.left.forwardslash.chevron.right"
        case .disk: "internaldrive"
        }
    }
}

struct MonitorItem: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let kind: MonitorKind
    var name: String
    let source: String
    var isEnabled = true
    var showInMenuBar = true
    var showInWidget = true
}

struct UsageSnapshot: Codable, Equatable, Sendable {
    var sessionRemaining: Int?
    var weeklyRemaining: Int?
    var sessionReset: Date?
    var weeklyReset: Date?
    var detail: String?
    var updatedAt = Date()

    var tightestRemaining: Int? {
        [sessionRemaining, weeklyRemaining].compactMap { $0 }.min()
    }
}

extension Notification.Name {
    static let monitorStoreChanged = Notification.Name("QuotaSpace.monitorStoreChanged")
}

