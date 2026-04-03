import UIKit
import Foundation
import OSLog

// MARK: - Permission Summary

struct PermissionSummary: Sendable, Identifiable {
    let id: String
    let permissionType: PermissionType
    let status: PermissionStatus
    let displayName: String
    let icon: String
    let description: String
    let settingsURL: URL?

    /// Canonical scoring policy for privacy permissions.
    /// "Appropriate" = user made an intentional choice (granted, denied, limited, or restricted).
    /// Only `notDetermined` is inappropriate — it means the permission hasn't been reviewed.
    /// This definition is shared by PrivacyViewModel.computeScore() and DashboardViewModel.
    var isAppropriate: Bool {
        switch status {
        case .authorized, .limited:
            return true
        case .denied, .restricted:
            return true
        case .notDetermined:
            return false
        }
    }

    var statusLabel: String {
        switch status {
        case .authorized: return "Allowed"
        case .limited: return "Limited"
        case .denied: return "Not Allowed"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Set"
        }
    }

    var statusColor: String {
        switch status {
        case .authorized: return "pcAccent"
        case .limited: return "pcWarning"
        case .denied: return "pcTextSecondary"
        case .restricted: return "pcTextSecondary"
        case .notDetermined: return "pcWarning"
        }
    }
}

// MARK: - Privacy Audit Result

struct PrivacyAuditResult: Sendable {
    let summaries: [PermissionSummary]
    let privacyScore: Int

    var authorizedCount: Int {
        summaries.filter { $0.status == .authorized || $0.status == .limited }.count
    }

    var deniedCount: Int {
        summaries.filter { $0.status == .denied }.count
    }

    var notDeterminedCount: Int {
        summaries.filter { $0.status == .notDetermined }.count
    }

    var reviewedCount: Int {
        summaries.filter { $0.status != .notDetermined }.count
    }
}

// MARK: - Privacy Auditor

@MainActor
@Observable
final class PrivacyAuditor {

    // MARK: - State

    private(set) var auditResult: PrivacyAuditResult?
    private(set) var isAuditing: Bool = false

    // MARK: - Private

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "PhoneCare", category: "PrivacyAuditor")

    /// The permission types we audit.
    /// Excludes unscorable permissions (e.g. localNetwork) — see PermissionType.unscorable.
    private let auditedPermissions: [PermissionType] = [
        .camera,
        .microphone,
        .location,
        .contacts,
        .photos,
        .calendar,
        .reminders,
    ]

    // MARK: - Audit

    func performAudit(permissionManager: PermissionManager) async -> PrivacyAuditResult {
        isAuditing = true
        defer { isAuditing = false }

        // Refresh all permission statuses
        await permissionManager.checkAllStatuses()

        var summaries: [PermissionSummary] = []

        for type in auditedPermissions {
            let status = permissionManager.status(for: type)
            let summary = makeSummary(for: type, status: status)
            summaries.append(summary)
        }

        // Calculate privacy score
        let total = summaries.count
        let appropriate = summaries.filter(\.isAppropriate).count
        let score = total > 0 ? Int((Double(appropriate) / Double(total) * 100).rounded()) : 100

        let result = PrivacyAuditResult(summaries: summaries, privacyScore: score)
        auditResult = result

        logger.info("Privacy audit complete. Score: \(score)/100")
        return result
    }

    // MARK: - Refresh on Foreground

    func refreshIfNeeded(permissionManager: PermissionManager) async {
        // Re-audit when app comes to foreground
        _ = await performAudit(permissionManager: permissionManager)
    }

    // MARK: - Settings URLs

    /// Opens the main app settings page
    nonisolated func openAppSettings() async {
        await MainActor.run {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
    }

    /// Generates a deep link to iOS Privacy settings for a specific permission
    static func settingsURL(for type: PermissionType) -> URL? {
        // iOS deep links to specific settings panes
        switch type {
        case .camera:
            return URL(string: UIApplication.openSettingsURLString)
        case .microphone:
            return URL(string: UIApplication.openSettingsURLString)
        case .location:
            return URL(string: UIApplication.openSettingsURLString)
        case .contacts:
            return URL(string: UIApplication.openSettingsURLString)
        case .photos:
            return URL(string: UIApplication.openSettingsURLString)
        case .calendar:
            return URL(string: UIApplication.openSettingsURLString)
        case .reminders:
            return URL(string: UIApplication.openSettingsURLString)
        case .bluetooth:
            return URL(string: UIApplication.openSettingsURLString)
        case .localNetwork:
            return URL(string: UIApplication.openSettingsURLString)
        case .health:
            return URL(string: "x-apple-health://")
        case .tracking:
            return URL(string: "App-prefs:Privacy&path=TRACKING")
        }
    }

    // MARK: - Summary Builder

    private func makeSummary(for type: PermissionType, status: PermissionStatus) -> PermissionSummary {
        let (icon, description) = permissionDetails(for: type, status: status)

        return PermissionSummary(
            id: type.rawValue,
            permissionType: type,
            status: status,
            displayName: type.displayName,
            icon: icon,
            description: description,
            settingsURL: Self.settingsURL(for: type)
        )
    }

    private func permissionDetails(for type: PermissionType, status: PermissionStatus) -> (icon: String, description: String) {
        switch type {
        case .camera:
            return (
                "camera.fill",
                status == .authorized
                    ? "Apps can use your camera. You can change this in Settings."
                    : status == .notDetermined
                    ? "No apps have asked to use your camera yet."
                    : "Camera access is turned off for this app."
            )
        case .microphone:
            return (
                "mic.fill",
                status == .authorized
                    ? "Apps can use your microphone. You can change this in Settings."
                    : status == .notDetermined
                    ? "No apps have asked to use your microphone yet."
                    : "Microphone access is turned off for this app."
            )
        case .location:
            return (
                "location.fill",
                status == .authorized
                    ? "This app can see your location. You can change this in Settings."
                    : status == .notDetermined
                    ? "Location access has not been set up yet."
                    : "Location access is turned off for this app."
            )
        case .contacts:
            return (
                "person.crop.circle.fill",
                status == .authorized
                    ? "This app can read your contacts to find duplicates."
                    : status == .notDetermined
                    ? "Contact access has not been set up yet."
                    : "Contact access is turned off. Enable it to find duplicate contacts."
            )
        case .photos:
            return (
                "photo.fill",
                status == .authorized
                    ? "This app can access your photo library to find duplicates."
                    : status == .limited
                    ? "This app can only see photos you selected."
                    : status == .notDetermined
                    ? "Photo access has not been set up yet."
                    : "Photo access is turned off. Enable it to find duplicate photos."
            )
        case .calendar:
            return (
                "calendar",
                status == .authorized
                    ? "Apps can access your calendar."
                    : status == .notDetermined
                    ? "Calendar access has not been set up yet."
                    : "Calendar access is turned off."
            )
        case .reminders:
            return (
                "checklist",
                status == .authorized
                    ? "Apps can access your reminders."
                    : status == .notDetermined
                    ? "Reminders access has not been set up yet."
                    : "Reminders access is turned off."
            )
        default:
            return ("questionmark.circle", "Permission status unknown.")
        }
    }
}
