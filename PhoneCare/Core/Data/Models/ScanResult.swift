import Foundation
import SwiftData

@Model
final class ScanResult {
    var id: UUID = UUID()
    var scanDate: Date = Date()

    // MARK: - Storage

    var totalStorage: Int64 = 0
    var usedStorage: Int64 = 0
    var recoverableStorage: Int64 = 0

    // MARK: - Photos

    var photoCount: Int = 0
    var duplicatePhotoCount: Int = 0
    var duplicatePhotoSize: Int64 = 0

    // MARK: - Contacts

    var contactCount: Int = 0
    var duplicateContactCount: Int = 0

    // MARK: - Battery

    var batteryHealth: Double?
    var batteryLevel: Double = 0

    // MARK: - Privacy & Health

    var privacyIssueCount: Int = 0

    /// Composite score 0-100.
    var healthScore: Int = 0

    // MARK: - Relationship

    @Relationship(deleteRule: .cascade, inverse: \ScanDetail.scanResult)
    var details: [ScanDetail]? = []

    // MARK: - Computed

    var freeStorage: Int64 { totalStorage - usedStorage }

    var usedStoragePercentage: Double {
        guard totalStorage > 0 else { return 0 }
        return Double(usedStorage) / Double(totalStorage) * 100
    }

    // MARK: - Init

    init(
        id: UUID = UUID(),
        scanDate: Date = Date(),
        totalStorage: Int64 = 0,
        usedStorage: Int64 = 0,
        recoverableStorage: Int64 = 0,
        photoCount: Int = 0,
        duplicatePhotoCount: Int = 0,
        duplicatePhotoSize: Int64 = 0,
        contactCount: Int = 0,
        duplicateContactCount: Int = 0,
        batteryHealth: Double? = nil,
        batteryLevel: Double = 0,
        privacyIssueCount: Int = 0,
        healthScore: Int = 0
    ) {
        self.id = id
        self.scanDate = scanDate
        self.totalStorage = totalStorage
        self.usedStorage = usedStorage
        self.recoverableStorage = recoverableStorage
        self.photoCount = photoCount
        self.duplicatePhotoCount = duplicatePhotoCount
        self.duplicatePhotoSize = duplicatePhotoSize
        self.contactCount = contactCount
        self.duplicateContactCount = duplicateContactCount
        self.batteryHealth = batteryHealth
        self.batteryLevel = batteryLevel
        self.privacyIssueCount = privacyIssueCount
        self.healthScore = healthScore
    }
}
