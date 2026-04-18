import Testing
import Foundation
@testable import PhoneCare

// MARK: - CleanupAction Tests

@Suite("CleanupAction")
struct CleanupActionTests {

    @Test("canUndo is true when not undone, not expired, and has undoData")
    func canUndoTrue() {
        let action = CleanupAction(
            actionType: .photoDelete,
            undoDeadline: Date().addingTimeInterval(3600),
            undoData: Data([0x01]),
            isUndone: false
        )
        #expect(action.canUndo == true)
    }

    @Test("canUndo is false when already undone")
    func canUndoFalseWhenUndone() {
        let action = CleanupAction(
            actionType: .photoDelete,
            undoDeadline: Date().addingTimeInterval(3600),
            undoData: Data([0x01]),
            isUndone: true
        )
        #expect(action.canUndo == false)
    }

    @Test("canUndo is false when undoData is nil")
    func canUndoFalseWhenNoData() {
        let action = CleanupAction(
            actionType: .photoDelete,
            undoDeadline: Date().addingTimeInterval(3600),
            undoData: nil,
            isUndone: false
        )
        #expect(action.canUndo == false)
    }

    @Test("canUndo is false when undo deadline has passed")
    func canUndoFalseWhenExpired() {
        let action = CleanupAction(
            actionType: .photoDelete,
            undoDeadline: Date().addingTimeInterval(-10),
            undoData: Data([0x01]),
            isUndone: false
        )
        #expect(action.canUndo == false)
    }

    @Test("isUndoExpired is true when deadline is in the past")
    func isUndoExpiredTrue() {
        let action = CleanupAction(
            actionType: .contactMerge,
            undoDeadline: Date().addingTimeInterval(-1)
        )
        #expect(action.isUndoExpired == true)
    }

    @Test("isUndoExpired is false when deadline is in the future")
    func isUndoExpiredFalse() {
        let action = CleanupAction(
            actionType: .contactMerge,
            undoDeadline: Date().addingTimeInterval(3600)
        )
        #expect(action.isUndoExpired == false)
    }

    @Test("cleanupType getter returns the correct enum")
    func cleanupTypeGetter() {
        let action = CleanupAction(actionType: .videoCompress)
        #expect(action.cleanupType == .videoCompress)
        #expect(action.actionType == "videoCompress")
    }

    @Test("cleanupType setter updates the raw value")
    func cleanupTypeSetter() {
        let action = CleanupAction(actionType: .photoDelete)
        action.cleanupType = .contactMerge
        #expect(action.actionType == "contactMerge")
        #expect(action.cleanupType == .contactMerge)
    }

    @Test("cleanupType defaults to photoDelete for unknown raw value")
    func cleanupTypeDefaultForUnknown() {
        let action = CleanupAction()
        action.actionType = "unknownType"
        #expect(action.cleanupType == .photoDelete)
    }

    @Test("Default initializer sets expected defaults")
    func defaultInit() {
        let action = CleanupAction()
        #expect(action.itemCount == 0)
        #expect(action.bytesFreed == 0)
        #expect(action.isUndone == false)
        #expect(action.undoData == nil)
    }

    @Test("CleanupActionType covers all cases")
    func allCases() {
        let cases = CleanupActionType.allCases
        #expect(cases.count == 3)
        #expect(cases.contains(.photoDelete))
        #expect(cases.contains(.contactMerge))
        #expect(cases.contains(.videoCompress))
    }
}

// MARK: - BatterySnapshot Tests

@Suite("BatterySnapshot")
struct BatterySnapshotTests {

    @Test("retentionDays is 365")
    func retentionDays() {
        #expect(BatterySnapshot.retentionDays == 365)
    }

    @Test("Default initializer sets level to 0")
    func defaultInit() {
        let snapshot = BatterySnapshot()
        #expect(snapshot.level == 0)
        #expect(snapshot.isCharging == false)
        #expect(snapshot.thermalState == 0)
        #expect(snapshot.maxCapacity == nil)
        #expect(snapshot.isLowPowerMode == false)
    }

    @Test("Custom initializer stores all values")
    func customInit() {
        let date = Date()
        let id = UUID()
        let snapshot = BatterySnapshot(
            id: id,
            date: date,
            level: 0.85,
            isCharging: true,
            thermalState: 2,
            maxCapacity: 0.92,
            isLowPowerMode: true
        )
        #expect(snapshot.id == id)
        #expect(snapshot.level == 0.85)
        #expect(snapshot.isCharging == true)
        #expect(snapshot.thermalState == 2)
        #expect(snapshot.maxCapacity == 0.92)
        #expect(snapshot.isLowPowerMode == true)
    }
}

// MARK: - ContactBackup Tests

@Suite("ContactBackup")
struct ContactBackupTests {

    @Test("retentionDays is 30")
    func retentionDays() {
        #expect(ContactBackup.retentionDays == 30)
    }

    @Test("undoDeadline defaults to mergeDate + 30 days")
    func defaultUndoDeadline() {
        let mergeDate = Date()
        let backup = ContactBackup(mergeDate: mergeDate)
        let expected = Calendar.current.date(byAdding: .day, value: 30, to: mergeDate)!
        // Allow 1 second tolerance
        let diff = abs(backup.undoDeadline.timeIntervalSince(expected))
        #expect(diff < 1.0)
    }

    @Test("Custom undoDeadline overrides default calculation")
    func customUndoDeadline() {
        let mergeDate = Date()
        let customDeadline = mergeDate.addingTimeInterval(3600)
        let backup = ContactBackup(mergeDate: mergeDate, undoDeadline: customDeadline)
        #expect(backup.undoDeadline == customDeadline)
    }

    @Test("canRestore is true when not restored and before deadline")
    func canRestoreTrue() {
        let backup = ContactBackup(
            mergeDate: Date(),
            undoDeadline: Date().addingTimeInterval(3600),
            isRestored: false
        )
        #expect(backup.canRestore == true)
    }

    @Test("canRestore is false when already restored")
    func canRestoreFalseWhenRestored() {
        let backup = ContactBackup(
            mergeDate: Date(),
            undoDeadline: Date().addingTimeInterval(3600),
            isRestored: true
        )
        #expect(backup.canRestore == false)
    }

    @Test("canRestore is false when past deadline")
    func canRestoreFalseWhenExpired() {
        let backup = ContactBackup(
            mergeDate: Date().addingTimeInterval(-86400 * 31),
            undoDeadline: Date().addingTimeInterval(-10),
            isRestored: false
        )
        #expect(backup.canRestore == false)
    }

    @Test("Default initializer sets expected values")
    func defaultInit() {
        let backup = ContactBackup()
        #expect(backup.originalContactData == Data())
        #expect(backup.mergedContactID == "")
        #expect(backup.isRestored == false)
    }
}

// MARK: - ScanResult Tests

@Suite("ScanResult")
struct ScanResultTests {

    @Test("freeStorage equals totalStorage minus usedStorage")
    func freeStorageComputed() {
        let scan = ScanResult(totalStorage: 1000, usedStorage: 600)
        #expect(scan.freeStorage == 400)
    }

    @Test("freeStorage is zero when fully used")
    func freeStorageZero() {
        let scan = ScanResult(totalStorage: 500, usedStorage: 500)
        #expect(scan.freeStorage == 0)
    }

    @Test("freeStorage can be negative if usedStorage exceeds total")
    func freeStorageNegative() {
        let scan = ScanResult(totalStorage: 100, usedStorage: 200)
        #expect(scan.freeStorage == -100)
    }

    @Test("usedStoragePercentage calculation")
    func usedStoragePercentage() {
        let scan = ScanResult(totalStorage: 1000, usedStorage: 750)
        #expect(scan.usedStoragePercentage == 75.0)
    }

    @Test("usedStoragePercentage is 0 when totalStorage is 0")
    func usedStoragePercentageZeroTotal() {
        let scan = ScanResult(totalStorage: 0, usedStorage: 0)
        #expect(scan.usedStoragePercentage == 0)
    }

    @Test("usedStoragePercentage is 100 when fully used")
    func usedStoragePercentage100() {
        let scan = ScanResult(totalStorage: 500, usedStorage: 500)
        #expect(scan.usedStoragePercentage == 100.0)
    }

    @Test("usedStoragePercentage for half used")
    func usedStoragePercentageHalf() {
        let scan = ScanResult(totalStorage: 200, usedStorage: 100)
        #expect(scan.usedStoragePercentage == 50.0)
    }

    @Test("Default initializer sets all values to zero/nil")
    func defaultInit() {
        let scan = ScanResult()
        #expect(scan.totalStorage == 0)
        #expect(scan.usedStorage == 0)
        #expect(scan.photoCount == 0)
        #expect(scan.duplicatePhotoCount == 0)
        #expect(scan.duplicatePhotoSize == 0)
        #expect(scan.contactCount == 0)
        #expect(scan.duplicateContactCount == 0)
        #expect(scan.batteryHealth == nil)
        #expect(scan.batteryLevel == 0)
        #expect(scan.privacyIssueCount == 0)
        #expect(scan.healthScore == 0)
    }

    @Test("Custom initializer stores all values")
    func customInit() {
        let scan = ScanResult(
            totalStorage: 64_000_000_000,
            usedStorage: 48_000_000_000,
            photoCount: 5000,
            duplicatePhotoCount: 150,
            duplicatePhotoSize: 500_000_000,
            contactCount: 300,
            duplicateContactCount: 25,
            batteryHealth: 0.95,
            batteryLevel: 0.80,
            privacyIssueCount: 3,
            healthScore: 72
        )
        #expect(scan.totalStorage == 64_000_000_000)
        #expect(scan.usedStorage == 48_000_000_000)
        #expect(scan.photoCount == 5000)
        #expect(scan.duplicatePhotoCount == 150)
        #expect(scan.batteryHealth == 0.95)
        #expect(scan.healthScore == 72)
    }
}

// MARK: - Privacy Manifesto Tests

@Suite("PrivacyManifesto")
struct PrivacyManifestoTests {

    @Test("Section title and summary are user-friendly")
    func sectionHeaderCopy() {
        #expect(PrivacyManifesto.sectionTitle == "Your Privacy")
        #expect(!PrivacyManifesto.summaryText.isEmpty)
    }

    @Test("No-collection list covers required trust claims")
    func requiredNoCollectionClaimsExist() {
        let joined = PrivacyManifesto.noCollectionPoints.joined(separator: " ").lowercased()
        #expect(joined.contains("photos"))
        #expect(joined.contains("contacts"))
        #expect(joined.contains("profiling"))
        #expect(joined.contains("advertising"))
        #expect(joined.contains("analytics"))
    }

    @Test("App Store privacy label summary is data not collected")
    func appStoreLabelSummary() {
        #expect(PrivacyManifesto.appStoreLabelTitle == "App Store Privacy Label")
        #expect(PrivacyManifesto.appStoreLabelValue == "Data Not Collected")
    }

    @Test("Privacy policy URL is valid HTTPS and points to legal docs")
    func privacyPolicyURLIsValid() {
        let url = PrivacyManifesto.privacyPolicyURL
        #expect(url != nil)
        #expect(url?.scheme == "https")
        #expect(url?.absoluteString.contains("privacy-policy") == true)
    }
}
