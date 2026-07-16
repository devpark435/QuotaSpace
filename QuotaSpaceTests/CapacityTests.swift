import XCTest

final class CapacityTests: XCTestCase {
    func testCapacityMath() {
        let capacity = DiskCapacity(available: 25, total: 100)

        XCTAssertEqual(capacity.availableFraction, 0.25)
        XCTAssertEqual(capacity.availablePercent, 25)
    }

    func testZeroTotalIsSafe() {
        XCTAssertEqual(DiskCapacity.unavailable.availableFraction, 0)
    }

    func testFindsClaudeConfigDirectoriesWithoutExecutingShell() throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let work = home.appendingPathComponent(".claude-work")
        try FileManager.default.createDirectory(at: work, withIntermediateDirectories: true)
        try Data().write(to: work.appendingPathComponent(".claude.json"))
        try "alias banana='CLAUDE_CONFIG_DIR=$HOME/.claude-work command claude'"
            .write(to: home.appendingPathComponent(".zshrc"), atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: home) }

        let matches = AccountDiscovery.discover(home: home)

        XCTAssertTrue(matches.contains { $0.kind == .claude && $0.name == "Banana" && $0.source == work.path })
    }
}
