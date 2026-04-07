import Foundation
import SwiftData

/// Tracks cumulative cleanup statistics for the Annual Health Report.
/// Updated each time a cleanup action completes successfully.
@Model
final class CleanupStats {
    var id: UUID = UUID()

    /// Total bytes freed across all cleanup actions
    var totalBytesFreed: Int64 = 0

    /// Total duplicate photos deleted
    var totalPhotosDeleted: Int = 0

    /// Total contacts merged
    var totalContactsMerged: Int = 0

    /// Total privacy audits completed
    var totalPrivacyAudits: Int = 0

    /// Total scans performed
    var totalScans: Int = 0

    /// Date the user first used the app (for anniversary detection)
    var firstUseDate: Date = Date()

    /// Date of the last recorded cleanup action
    var lastCleanupDate: Date?

    init() {}

    // MARK: - Recording

    func recordPhotoCleanup(count: Int, bytesFreed: Int64) {
        totalPhotosDeleted += count
        totalBytesFreed += bytesFreed
        lastCleanupDate = Date()
    }

    func recordContactMerge(count: Int) {
        totalContactsMerged += count
        lastCleanupDate = Date()
    }

    func recordPrivacyAudit() {
        totalPrivacyAudits += 1
    }

    func recordScan() {
        totalScans += 1
    }
}
