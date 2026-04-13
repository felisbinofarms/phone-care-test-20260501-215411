import SwiftUI

enum LaunchArguments {
    static let skipOnboardingForUITests = "UITestsSkipOnboarding"
    static let skipStoreKitForUITests = "UITestsSkipStoreKit"

    static func contains(_ argument: String) -> Bool {
        ProcessInfo.processInfo.arguments.contains(argument)
    }
}

@Observable
final class AppState {
    var hasCompletedOnboarding: Bool = false {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }

    var selectedTab: Tab = .home
    var deepLinkTarget: DeepLink?

    var appearanceMode: AppearanceMode = .system {
        didSet { UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode") }
    }

    init() {
        if LaunchArguments.contains(LaunchArguments.skipOnboardingForUITests) {
            self.hasCompletedOnboarding = true
        } else {
            self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        }
        let rawMode = UserDefaults.standard.integer(forKey: "appearanceMode")
        self.appearanceMode = AppearanceMode(rawValue: rawMode) ?? .system
    }

    var resolvedColorScheme: ColorScheme? {
        switch appearanceMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum Tab: String, CaseIterable, Identifiable {
    case home, storage, photos, privacy, settings
    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .storage: "Storage"
        case .photos: "Photos"
        case .privacy: "Privacy"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: "heart.text.square.fill"
        case .storage: "internaldrive.fill"
        case .photos: "photo.on.rectangle.fill"
        case .privacy: "lock.shield.fill"
        case .settings: "gearshape.fill"
        }
    }
}

enum AppearanceMode: Int, CaseIterable, Identifiable {
    case system = 0
    case light = 1
    case dark = 2
    var id: Int { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}

enum DeepLink: Hashable {
    case dashboard
    case storage
    case photos
    case privacy
    case settings
    case guidedFlow(GuidedFlowType)
}

enum GuidedFlowType: String, Hashable {
    case freeUpSpace
    case cleanPhotos
    case cleanContacts
    case reviewPrivacy
}
