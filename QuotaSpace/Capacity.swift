import Foundation

struct DiskCapacity: Equatable, Sendable {
    let available: Int64
    let total: Int64

    var availableFraction: Double { total > 0 ? Double(available) / Double(total) : 0 }
    var availablePercent: Int { Int((availableFraction * 100).rounded()) }
    var availableText: String { ByteCountFormatter.string(fromByteCount: available, countStyle: .file) }
    var totalText: String { ByteCountFormatter.string(fromByteCount: total, countStyle: .file) }

    static func current(at url: URL = URL(fileURLWithPath: "/")) throws -> DiskCapacity {
        let values = try url.resourceValues(forKeys: [
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeTotalCapacityKey,
        ])
        guard let available = values.volumeAvailableCapacityForImportantUsage,
              let total = values.volumeTotalCapacity else {
            throw CocoaError(.fileReadUnknown)
        }
        return DiskCapacity(available: available, total: Int64(total))
    }

    static let unavailable = DiskCapacity(available: 0, total: 0)
}
