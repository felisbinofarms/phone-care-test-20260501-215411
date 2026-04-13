import SwiftUI

enum PrivacyManifesto {
    static let sectionTitle = "Your Privacy"
    static let summaryText = "No trackers. All processing stays on your iPhone."
    static let detailsText = "PhoneCare runs fully on-device. We do not collect personal data, use third-party analytics SDKs, or upload your photos and contacts to external servers."

    static let noCollectionPoints: [String] = [
        "No photos are uploaded",
        "No contacts are sent to servers",
        "No usage profiling",
        "No advertising ID tracking",
        "No third-party analytics SDKs"
    ]

    static let appStoreLabelTitle = "App Store Privacy Label"
    static let appStoreLabelValue = "Data Not Collected"

    // Reused by Settings surfaces and intended as the single source for legal links.
    static let privacyPolicyURLString = "https://github.com/pyroforbes/phone-care-ios/blob/main/docs/legal/privacy-policy.md"
    static var privacyPolicyURL: URL? { URL(string: privacyPolicyURLString) }
    static let termsOfServiceURLString = "https://github.com/pyroforbes/phone-care-ios/blob/main/docs/legal/terms-of-service.md"
    static var termsOfServiceURL: URL? { URL(string: termsOfServiceURLString) }
}

@MainActor
@Observable
final class SettingsViewModel {

    // MARK: - State

    var appearanceMode: AppearanceMode = .system
    var weeklyNotification: Bool = true
    var duplicateAlerts: Bool = true
    var batteryAlerts: Bool = true

    var showDeleteConfirmation: Bool = false
    var showDeleteFinalConfirmation: Bool = false
    var isDeleting: Bool = false
    var deleteComplete: Bool = false

    // MARK: - Load

    func load(dataManager: DataManager, appState: AppState) {
        appearanceMode = appState.appearanceMode

        do {
            let prefs = try dataManager.userPreferences()
            weeklyNotification = prefs.weeklyNotification
            duplicateAlerts = prefs.duplicateAlerts
            batteryAlerts = prefs.batteryAlerts
        } catch {
            // Use defaults
        }
    }

    // MARK: - Save

    func saveAppearance(appState: AppState) {
        appState.appearanceMode = appearanceMode
    }

    func saveNotifications(dataManager: DataManager) {
        do {
            let prefs = try dataManager.userPreferences()
            prefs.weeklyNotification = weeklyNotification
            prefs.duplicateAlerts = duplicateAlerts
            prefs.batteryAlerts = batteryAlerts
            try dataManager.saveContext()
        } catch {
            // Silent fail
        }
    }

    // MARK: - Delete All Data

    func deleteAllData(dataManager: DataManager) {
        isDeleting = true
        do {
            try dataManager.deleteAllData()
            deleteComplete = true
        } catch {
            // Show error state
        }
        isDeleting = false
    }

    // MARK: - App Info

    var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}
