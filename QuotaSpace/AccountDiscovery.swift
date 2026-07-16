import Foundation

struct AccountDiscovery {
    static func discover(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> [MonitorItem] {
        var aliases: [String: String] = [:]
        for file in [".zshrc", ".zprofile", ".bashrc", ".bash_profile", ".config/fish/config.fish"] {
            let url = home.appendingPathComponent(file)
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            for match in configDirectoryMatches(in: text, home: home) { aliases[match.path] = match.name }
        }

        var paths = Set(aliases.keys)
        paths.insert(home.appendingPathComponent(".claude").path)
        if let entries = try? FileManager.default.contentsOfDirectory(at: home, includingPropertiesForKeys: nil) {
            for entry in entries where entry.lastPathComponent.hasPrefix(".claude-") && isClaudeProfile(entry) {
                paths.insert(entry.path)
            }
        }

        var items = paths.compactMap { path -> MonitorItem? in
            let url = URL(fileURLWithPath: path)
            guard isClaudeProfile(url) else { return nil }
            let suffix = url.lastPathComponent.replacingOccurrences(of: ".claude-", with: "")
            let fallback = url.lastPathComponent == ".claude" ? "Default" : suffix.capitalized
            return MonitorItem(
                id: "claude:\(path)",
                kind: .claude,
                name: aliases[path]?.replacingOccurrences(of: "claude-", with: "").capitalized ?? fallback,
                source: path
            )
        }

        let codexHome = home.appendingPathComponent(".codex")
        if FileManager.default.fileExists(atPath: codexHome.path) {
            items.append(MonitorItem(id: "codex:\(codexHome.path)", kind: .codex, name: "Codex", source: codexHome.path))
        }
        items.append(MonitorItem(id: "disk:/", kind: .disk, name: "Macintosh HD", source: "/", showInMenuBar: false))
        return items.sorted { ($0.kind.rawValue, $0.name) < ($1.kind.rawValue, $1.name) }
    }

    static func configDirectoryMatches(in text: String, home: URL) -> [(name: String, path: String)] {
        let pattern = #"(?m)(?:alias\s+([\w-]+)\s*=.*)?CLAUDE_CONFIG_DIR\s*=\s*["']?([^\s"';]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        return regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap { match in
            guard let pathRange = Range(match.range(at: 2), in: text) else { return nil }
            let expanded = String(text[pathRange])
                .replacingOccurrences(of: "${HOME}", with: home.path)
                .replacingOccurrences(of: "$HOME", with: home.path)
                .replacingOccurrences(of: "~", with: home.path)
            let name = Range(match.range(at: 1), in: text).map { String(text[$0]) }
                ?? URL(fileURLWithPath: expanded).lastPathComponent
            return (name, URL(fileURLWithPath: expanded).standardizedFileURL.path)
        }
    }

    private static func isClaudeProfile(_ url: URL) -> Bool {
        [".credentials.json", ".claude.json", "history.jsonl"].contains {
            FileManager.default.fileExists(atPath: url.appendingPathComponent($0).path)
        }
    }
}
