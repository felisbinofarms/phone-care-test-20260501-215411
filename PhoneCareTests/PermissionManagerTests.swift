import Testing
import Foundation
@testable import PhoneCare

@Suite("PermissionManager — types and summaries")
struct PermissionManagerTests {

    // MARK: - PermissionType coverage

    @Test("PermissionType.allCases contains the expected 11 types")
    func permissionType_allCases_count() {
        #expect(PermissionType.allCases.count == 11)
    }

    @Test("Each PermissionType has a non-empty displayName")
    func permissionType_displayNames_nonEmpty() {
        for type in PermissionType.allCases {
            #expect(!type.displayName.isEmpty, "displayName is empty for \(type.rawValue)")
        }
    }

    @Test("PermissionType id equals its rawValue")
    func permissionType_idEqualsRawValue() {
        for type in PermissionType.allCases {
            #expect(type.id == type.rawValue)
        }
    }

    // MARK: - PermissionStatus raw values

    @Test("PermissionStatus raw values are stable strings")
    func permissionStatus_rawValues() {
        #expect(PermissionStatus.authorized.rawValue == "authorized")
        #expect(PermissionStatus.denied.rawValue == "denied")
        #expect(PermissionStatus.notDetermined.rawValue == "notDetermined")
        #expect(PermissionStatus.restricted.rawValue == "restricted")
        #expect(PermissionStatus.limited.rawValue == "limited")
    }

    // MARK: - PermissionSummary: isAppropriate

    @Test("authorized status is appropriate")
    func permissionSummary_authorized_isAppropriate() {
        let summary = makeSummary(status: .authorized)
        #expect(summary.isAppropriate == true)
    }

    @Test("limited status is appropriate")
    func permissionSummary_limited_isAppropriate() {
        let summary = makeSummary(status: .limited)
        #expect(summary.isAppropriate == true)
    }

    @Test("denied status is appropriate (user made a conscious choice)")
    func permissionSummary_denied_isAppropriate() {
        let summary = makeSummary(status: .denied)
        #expect(summary.isAppropriate == true)
    }

    @Test("restricted status is appropriate")
    func permissionSummary_restricted_isAppropriate() {
        let summary = makeSummary(status: .restricted)
        #expect(summary.isAppropriate == true)
    }

    @Test("notDetermined status is NOT appropriate (not yet reviewed)")
    func permissionSummary_notDetermined_isNotAppropriate() {
        let summary = makeSummary(status: .notDetermined)
        #expect(summary.isAppropriate == false)
    }

    // MARK: - PermissionSummary: statusLabel

    @Test("statusLabel returns correct display strings for every status")
    func permissionSummary_statusLabels() {
        #expect(makeSummary(status: .authorized).statusLabel == "Allowed")
        #expect(makeSummary(status: .limited).statusLabel == "Limited")
        #expect(makeSummary(status: .denied).statusLabel == "Not Allowed")
        #expect(makeSummary(status: .restricted).statusLabel == "Restricted")
        #expect(makeSummary(status: .notDetermined).statusLabel == "Not Set")
    }

    // MARK: - PermissionManager initial state

    @Test("PermissionManager initialises every permission type to notDetermined")
    @MainActor
    func permissionManager_initialStatuses() {
        let manager = PermissionManager()
        for type in PermissionType.allCases {
            #expect(manager.status(for: type) == .notDetermined,
                    "Expected notDetermined for \(type.rawValue)")
        }
    }

    @Test("authorizedCount starts at zero")
    @MainActor
    func permissionManager_initialAuthorizedCount() {
        let manager = PermissionManager()
        #expect(manager.authorizedCount == 0)
    }

    @Test("deniedCount starts at zero")
    @MainActor
    func permissionManager_initialDeniedCount() {
        let manager = PermissionManager()
        #expect(manager.deniedCount == 0)
    }

    // MARK: - Helpers

    private func makeSummary(status: PermissionStatus) -> PermissionSummary {
        PermissionSummary(
            id: "camera",
            permissionType: .camera,
            status: status,
            displayName: "Camera",
            icon: "camera.fill",
            description: "Test",
            settingsURL: nil
        )
    }
}
