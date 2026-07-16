import Foundation
import CryptoKit
import Security

enum UsageFetchError: LocalizedError {
    case credentialsUnavailable
    case invalidResponse
    case commandUnavailable(String)
    case timedOut

    var errorDescription: String? {
        switch self {
        case .credentialsUnavailable: "Open Claude Code and sign in to show usage."
        case .invalidResponse: "The provider returned an unsupported usage response."
        case let .commandUnavailable(name): "\(name) is not available."
        case .timedOut: "The provider did not respond in time."
        }
    }
}

struct ClaudeUsageFetcher {
    static func fetch() async throws -> UsageSnapshot {
        guard let credentials = keychainCredentials().flatMap(Credentials.init),
              !credentials.isExpired else { throw UsageFetchError.credentialsUnavailable }
        let email = try await tokenEmail(credentials.accessToken)
        return try await usage(token: credentials.accessToken, detail: email)
    }

    private static func usage(token: String, detail: String) async throws -> UsageSnapshot {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/api/oauth/usage")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200,
              let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] else {
            throw UsageFetchError.invalidResponse
        }
        let session = window(json["five_hour"])
        let weekly = window(json["seven_day"])
        guard session.remaining != nil || weekly.remaining != nil else { throw UsageFetchError.invalidResponse }
        return UsageSnapshot(
            sessionRemaining: session.remaining,
            weeklyRemaining: weekly.remaining,
            sessionReset: session.reset,
            weeklyReset: weekly.reset,
            detail: detail
        )
    }

    private static func tokenEmail(_ token: String) async throws -> String {
        let key = SHA256.hash(data: Data(token.utf8)).map { String(format: "%02x", $0) }.joined()
        var cache = UserDefaults.standard.dictionary(forKey: "claudeTokenEmails") as? [String: String] ?? [:]
        if let email = cache[key] { return email }

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/api/oauth/profile")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200,
              let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let account = root["account"] as? [String: Any],
              let email = account["email"] as? String else {
            throw UsageFetchError.invalidResponse
        }
        cache[key] = email
        UserDefaults.standard.set(cache, forKey: "claudeTokenEmails")
        return email
    }

    private static func keychainCredentials() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "Claude Code-credentials",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    private struct Credentials {
        let accessToken: String
        let expiresAt: Date?

        init?(_ data: Data) {
            guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let oauth = root["claudeAiOauth"] as? [String: Any],
                  let accessToken = oauth["accessToken"] as? String else { return nil }
            self.accessToken = accessToken
            self.expiresAt = (oauth["expiresAt"] as? NSNumber)
                .map { Date(timeIntervalSince1970: $0.doubleValue / 1000) }
        }

        var isExpired: Bool { expiresAt.map { $0 <= Date() } ?? false }
    }

    private static func window(_ value: Any?) -> (remaining: Int?, reset: Date?) {
        guard let value = value as? [String: Any] else { return (nil, nil) }
        let used = (value["utilization"] as? NSNumber)?.doubleValue
        let remaining = used.map { max(0, min(100, 100 - Int($0.rounded()))) }
        let reset = (value["resets_at"] as? String).flatMap { ISO8601DateFormatter().date(from: $0) }
        return (remaining, reset)
    }
}

struct CodexUsageFetcher {
    static func fetch() async throws -> UsageSnapshot {
        guard let executable = ["/opt/homebrew/bin/codex", "/usr/local/bin/codex"].first(where: FileManager.default.isExecutableFile) else {
            throw UsageFetchError.commandUnavailable("Codex")
        }
        let process = Process()
        let input = Pipe()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = ["-s", "read-only", "-a", "untrusted", "app-server"]
        process.standardInput = input
        process.standardOutput = output
        process.standardError = Pipe()
        try process.run()

        let requests = [
            #"{"method":"initialize","id":1,"params":{"clientInfo":{"name":"quotaspace","title":"QuotaSpace","version":"0.1.0"}}}"#,
            #"{"method":"initialized","params":{}}"#,
            #"{"method":"account/rateLimits/read","id":2,"params":{}}"#,
        ].joined(separator: "\n") + "\n"
        try input.fileHandleForWriting.write(contentsOf: Data(requests.utf8))

        return try await withThrowingTaskGroup(of: UsageSnapshot.self) { group in
            group.addTask { try await readUsage(from: output.fileHandleForReading) }
            group.addTask {
                try await Task.sleep(for: .seconds(10))
                throw UsageFetchError.timedOut
            }
            do {
                let result = try await group.next() ?? { throw UsageFetchError.invalidResponse }()
                process.terminate()
                group.cancelAll()
                return result
            } catch {
                process.terminate()
                group.cancelAll()
                throw error
            }
        }
    }

    private static func readUsage(from handle: FileHandle) async throws -> UsageSnapshot {
        for try await line in handle.bytes.lines {
            guard let data = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  (json["id"] as? NSNumber)?.intValue == 2 else { continue }
            guard let result = json["result"] as? [String: Any] else { throw UsageFetchError.invalidResponse }
            return parse(result)
        }
        throw UsageFetchError.invalidResponse
    }

    private static func parse(_ result: [String: Any]) -> UsageSnapshot {
        let limits = (result["rateLimits"] as? [String: Any]) ?? result
        let primary = window(limits["primary"] ?? limits["primaryWindow"])
        let secondary = window(limits["secondary"] ?? limits["secondaryWindow"])
        return UsageSnapshot(
            sessionRemaining: primary.remaining,
            weeklyRemaining: secondary.remaining,
            sessionReset: primary.reset,
            weeklyReset: secondary.reset,
            detail: "Codex"
        )
    }

    private static func window(_ value: Any?) -> (remaining: Int?, reset: Date?) {
        guard let value = value as? [String: Any] else { return (nil, nil) }
        let used = (value["usedPercent"] as? NSNumber)?.doubleValue
            ?? (value["used_percent"] as? NSNumber)?.doubleValue
        let remaining = used.map { max(0, min(100, 100 - Int($0.rounded()))) }
        let timestamp = (value["resetsAt"] as? NSNumber)?.doubleValue
            ?? (value["resets_at"] as? NSNumber)?.doubleValue
        return (remaining, timestamp.map(Date.init(timeIntervalSince1970:)))
    }
}
