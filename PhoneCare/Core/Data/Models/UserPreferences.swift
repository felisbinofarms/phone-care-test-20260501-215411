import Foundation
import SwiftData

@Model
final class UserPreferences {

    // MARK: - Onboarding Responses

    var goals: [String] = []
    var phoneFeeling: String = ""
    var techSavvyLevel: Int = 1

    // MARK: - Dashboard Customisation

    var cardOrder: [String] = [
        "healthScore",
        "storage",
        "photos",
        "contacts",
        "battery",
        "privacy"
    ]

    // MARK: - Appearance

    /// 0 = system, 1 = light, 2 = dark
    var appearanceMode: Int = 0

    // MARK: - Notifications

    var weeklyNotification: Bool = true
    var duplicateAlerts: Bool = true
    var batteryAlerts: Bool = true

    // MARK: - Onboarding State

    var onboardingCompleted: Bool = false
    var onboardingCompletedAt: Date?

    // MARK: - Paywall

    var paywallLastShownAt: Date?

    // MARK: - Share Prompts

    var sharePromptLastShownAt: Date?

    // MARK: - Init

    init(
        goals: [String] = [],
        phoneFeeling: String = "",
        techSavvyLevel: Int = 1,
        cardOrder: [String] = [
            "healthScore", "storage", "photos",
            "contacts", "battery", "privacy"
        ],
        appearanceMode: Int = 0,
        weeklyNotification: Bool = true,
        duplicateAlerts: Bool = true,
        batteryAlerts: Bool = true,
        onboardingCompleted: Bool = false,
        onboardingCompletedAt: Date? = nil,
        paywallLastShownAt: Date? = nil,
        sharePromptLastShownAt: Date? = nil
    ) {
        self.goals = goals
        self.phoneFeeling = phoneFeeling
        self.techSavvyLevel = techSavvyLevel
        self.cardOrder = cardOrder
        self.appearanceMode = appearanceMode
        self.weeklyNotification = weeklyNotification
        self.duplicateAlerts = duplicateAlerts
        self.batteryAlerts = batteryAlerts
        self.onboardingCompleted = onboardingCompleted
        self.onboardingCompletedAt = onboardingCompletedAt
        self.paywallLastShownAt = paywallLastShownAt
        self.sharePromptLastShownAt = sharePromptLastShownAt
    }
}
