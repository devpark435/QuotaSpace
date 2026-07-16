import Foundation

struct AccountDiscovery {
    static func discover(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> [MonitorItem] {
        var items = [
            MonitorItem(id: "claude:keychain", kind: .claude, name: "Claude", source: "Current Claude Code account")
        ]

        let codexHome = home.appendingPathComponent(".codex")
        if FileManager.default.fileExists(atPath: codexHome.path) {
            items.append(MonitorItem(id: "codex:\(codexHome.path)", kind: .codex, name: "Codex", source: codexHome.path))
        }
        items.append(MonitorItem(id: "disk:/", kind: .disk, name: "Macintosh HD", source: "/", showInMenuBar: false))
        return items.sorted { ($0.kind.rawValue, $0.name) < ($1.kind.rawValue, $1.name) }
    }
}
