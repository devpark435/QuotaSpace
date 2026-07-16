import XCTest

final class CapacityTests: XCTestCase {
    func testCapacityMath() {
        let capacity = DiskCapacity(available: 25, total: 100)

        XCTAssertEqual(capacity.availableFraction, 0.25)
        XCTAssertEqual(capacity.availablePercent, 25)
        XCTAssertEqual(UsageDisplayMode.remaining.percent(fromRemaining: 83), 83)
        XCTAssertEqual(UsageDisplayMode.used.percent(fromRemaining: 83), 17)
    }

    func testZeroTotalIsSafe() {
        XCTAssertEqual(DiskCapacity.unavailable.availableFraction, 0)
    }

    func testDiscoversOnlyOneCurrentClaudeAccount() throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: home.appendingPathComponent(".claude-work"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: home) }

        let claude = AccountDiscovery.discover(home: home).filter { $0.kind == .claude }
        XCTAssertEqual(claude.count, 1)
        XCTAssertEqual(claude.first?.id, "claude:keychain")
    }
}
