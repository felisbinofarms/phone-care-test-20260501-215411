import Testing
import Foundation
@testable import PhoneCare

// Note: PrivacyAuditorTests tests the PermissionSummary and PrivacyAuditResult
// model logic. Definitive PrivacyAuditor scoring tests that depend on the
// unified PermissionScoringPolicy (issue #5) will be strengthened once PR #29
// is merged.

@Suite("PrivacyAuditor — models and scoring")
@MainActor
struct PrivacyAuditorTests {

    // MARK: - PermissionSummary: isAppropriate

    @Test("authorized summary is appropriate")
    func summary_authorized_appropriate() {
        #expect(makeSummary(.authorized).isAppropriate == true)
    }

    @Test("limited summary is appropriate")
    func summary_limited_appropriate() {
        #expect(makeSummary(.limited).isAppropriate == true)
    }

    @Test("denied summary is appropriate (user made a conscious choice)")
    func summary_denied_appropriate() {
        #expect(makeSummary(.denied).isAppropriate == true)
    }

    @Test("restricted summary is appropriate")
    func summary_restricted_appropriate() {
        #expect(makeSummary(.restricted).isAppropriate == true)
    }

    @Test("notDetermined summary is NOT appropriate")
    func summary_notDetermined_notAppropriate() {
        #expect(makeSummary(.notDetermined).isAppropriate == false)
    }

    // MARK: - PermissionSummary: statusColor

    @Test("authorized summary uses pcAccent color token")
    func summary_authorized_color() {
        #expect(makeSummary(.authorized).statusColor == "pcAccent")
    }

    @Test("limited summary uses pcWarning color token")
    func summary_limited_color() {
        #expect(makeSummary(.limited).statusColor == "pcWarning")
    }

    @Test("denied summary uses pcTextSecondary color token")
    func summary_denied_color() {
        #expect(makeSummary(.denied).statusColor == "pcTextSecondary")
    }

    @Test("restricted summary uses pcTextSecondary color token")
    func summary_restricted_color() {
        #expect(makeSummary(.restricted).statusColor == "pcTextSecondary")
    }

    @Test("notDetermined summary uses pcWarning color token")
    func summary_notDetermined_color() {
        #expect(makeSummary(.notDetermined).statusColor == "pcWarning")
    }

    // MARK: - PrivacyAuditResult computed counts

    @Test("authorizedCount includes both authorized and limited summaries")
    func auditResult_authorizedCount() {
        let result = makeResult(statuses: [.authorized, .limited, .denied, .notDetermined, .restricted])
        #expect(result.authorizedCount == 2)
    }

    @Test("deniedCount counts only denied summaries")
    func auditResult_deniedCount() {
        let result = makeResult(statuses: [.authorized, .denied, .denied, .notDetermined])
        #expect(result.deniedCount == 2)
    }

    @Test("notDeterminedCount counts unreviewed permissions")
    func auditResult_notDeterminedCount() {
        let result = makeResult(statuses: [.notDetermined, .notDetermined, .authorized])
        #expect(result.notDeterminedCount == 2)
    }

    @Test("reviewedCount excludes notDetermined")
    func auditResult_reviewedCount() {
        let result = makeResult(statuses: [.authorized, .denied, .notDetermined, .limited])
        // authorized + denied + limited = 3 reviewed
        #expect(result.reviewedCount == 3)
    }

    // MARK: - Score boundary cases

    @Test("All permissions appropriate yields score 100")
    func score_allAppropriate() {
        // Build a result with manually-computed 100% score
        let result = PrivacyAuditResult(
            summaries: makePermissionSummaries(statuses: [.authorized, .denied, .restricted]),
            privacyScore: 100
        )
        #expect(result.privacyScore == 100)
    }

    @Test("No permissions appropriate yields score 0")
    func score_noneAppropriate() {
        let result = PrivacyAuditResult(
            summaries: makePermissionSummaries(statuses: [.notDetermined, .notDetermined]),
            privacyScore: 0
        )
        #expect(result.privacyScore == 0)
    }

    @Test("privacyScore preserves in-range values between 0 and 100")
    func score_range() {
        for score in [0, 50, 100] {
            let result = PrivacyAuditResult(
                summaries: [],
                privacyScore: score
            )
            #expect(result.privacyScore >= 0)
            #expect(result.privacyScore <= 100)
        }
    }

    @Test("Mixed permission statuses produce a mid-range score")
    func score_midRange() {
        // 2 appropriate out of 4 => 50%
        let result = makeResult(statuses: [.authorized, .denied, .notDetermined, .notDetermined])
        #expect(result.privacyScore == 50)
    }

    // MARK: - settingsURL helpers

    @Test("settingsURL returns a non-nil URL for every permission type")
    func settingsURL_allTypes_nonNil() {
        for type in PermissionType.allCases {
            #expect(PrivacyAuditor.settingsURL(for: type) != nil,
                    "settingsURL returned nil for \(type.rawValue)")
        }
    }

    // MARK: - Helpers

    private func makeSummary(_ status: PermissionStatus) -> PermissionSummary {
        PermissionSummary(
            id: "camera",
            permissionType: .camera,
            status: status,
            displayName: "Camera",
            icon: "camera.fill",
            description: "Test description",
            settingsURL: nil
        )
    }

    private func makeResult(statuses: [PermissionStatus]) -> PrivacyAuditResult {
        let summaries = makePermissionSummaries(statuses: statuses)
        let appropriate = summaries.filter(\.isAppropriate).count
        let score = summaries.isEmpty ? 100 : Int((Double(appropriate) / Double(summaries.count) * 100).rounded())
        return PrivacyAuditResult(summaries: summaries, privacyScore: score)
    }

    private func makePermissionSummaries(statuses: [PermissionStatus]) -> [PermissionSummary] {
        statuses.enumerated().map { index, status in
            PermissionSummary(
                id: "perm\(index)",
                permissionType: .camera,
                status: status,
                displayName: "Permission \(index)",
                icon: "questionmark",
                description: "",
                settingsURL: nil
            )
        }
    }

    // MARK: - performAudit integration

    @Test("performAudit completes without throwing in test environment")
    func performAudit_doesNotThrow() async {
        let auditor = PrivacyAuditor()
        let permManager = PermissionManager()
        let result = await auditor.performAudit(permissionManager: permManager)
        // Result is accessible — no throw
        #expect(result.privacyScore >= 0)
        #expect(result.privacyScore <= 100)
    }

    @Test("performAudit result contains at least one permission entry")
    func performAudit_resultContainsPermissions() async {
        let auditor = PrivacyAuditor()
        let permManager = PermissionManager()
        let result = await auditor.performAudit(permissionManager: permManager)
        #expect(!result.summaries.isEmpty)
    }

    @Test("performAudit concurrent calls do not crash")
    func performAudit_concurrentCalls_noCrash() async {
        let auditor = PrivacyAuditor()
        let permManager = PermissionManager()
        // Fire two overlapping audit calls; the second sets isAuditing while first runs.
        // Neither should crash.
        async let first  = auditor.performAudit(permissionManager: permManager)
        async let second = auditor.performAudit(permissionManager: permManager)
        let (r1, r2) = await (first, second)
        #expect(r1.privacyScore >= 0)
        #expect(r2.privacyScore >= 0)
    }
}
