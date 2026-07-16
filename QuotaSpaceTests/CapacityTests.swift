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
}

