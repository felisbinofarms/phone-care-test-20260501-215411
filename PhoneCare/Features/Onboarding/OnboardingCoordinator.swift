import SwiftUI

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable, Comparable {
    case welcome = 0
    case goals
    case phoneFeeling
    case techSavvy
    case permissionPriming
    case scanning
    case results
    case personalPlan
    case honestAlternative
    case paywall
    case welcomeHome

    static func < (lhs: OnboardingStep, rhs: OnboardingStep) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var canGoBack: Bool {
        switch self {
        case .welcome, .scanning, .results, .welcomeHome:
            return false
        default:
            return true
        }
    }

    var canSkip: Bool {
        switch self {
        case .goals, .phoneFeeling, .techSavvy:
            return true
        default:
            return false
        }
    }

    var next: OnboardingStep? {
        let allCases = OnboardingStep.allCases
        guard let index = allCases.firstIndex(of: self),
              index + 1 < allCases.count else { return nil }
        return allCases[index + 1]
    }

    var previous: OnboardingStep? {
        let allCases = OnboardingStep.allCases
        guard let index = allCases.firstIndex(of: self),
              index > 0 else { return nil }
        return allCases[index - 1]
    }

    /// Progress fraction for the step indicator (0.0 - 1.0)
    var progressFraction: Double {
        Double(rawValue) / Double(OnboardingStep.allCases.count - 1)
    }
}

// MARK: - Onboarding Coordinator

struct OnboardingCoordinator: View {
    @Environment(AppState.self) private var appState
    @Environment(DataManager.self) private var dataManager
    @Environment(PermissionManager.self) private var permissionManager
    @Environment(SubscriptionManager.self) private var subscriptionManager

    @State private var currentStep: OnboardingStep = .welcome
    @State private var viewModel = OnboardingViewModel()
    @State private var storageAnalyzer = StorageAnalyzer()
    @State private var photoAnalyzer = PhotoAnalyzer()
    @State private var contactAnalyzer = ContactAnalyzer()
    @State private var batteryMonitor = BatteryMonitor()
    @State private var privacyAuditor = PrivacyAuditor()

    var body: some View {
        ZStack {
            Color.pcBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar (hidden on welcome and welcomeHome)
                if currentStep != .welcome && currentStep != .welcomeHome {
                    stepProgressBar
                        .padding(.horizontal, PCTheme.Spacing.md)
                        .padding(.top, PCTheme.Spacing.sm)
                }

                // Step content
                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }

    // MARK: - Progress Bar

    private var stepProgressBar: some View {
        VStack(spacing: PCTheme.Spacing.xs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.pcBorder)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.pcAccent)
                        .frame(
                            width: geometry.size.width * currentStep.progressFraction,
                            height: 4
                        )
                }
            }
            .frame(height: 4)
            .accessibilityLabel("Onboarding progress")
            .accessibilityValue("\(Int(currentStep.progressFraction * 100)) percent")
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .welcome:
            WelcomeView(onContinue: goForward)

        case .goals:
            GoalsQuestionView(
                viewModel: viewModel,
                onContinue: goForward,
                onBack: goBack,
                onSkip: goForward
            )

        case .phoneFeeling:
            PhoneFeelingView(
                viewModel: viewModel,
                onContinue: goForward,
                onBack: goBack,
                onSkip: goForward
            )

        case .techSavvy:
            TechSavvyView(
                viewModel: viewModel,
                onContinue: goForward,
                onBack: goBack,
                onSkip: goForward
            )

        case .permissionPriming:
            PermissionPrimingView(
                permissionManager: permissionManager,
                onContinue: goForward,
                onBack: goBack
            )

        case .scanning:
            LiveScanView(
                viewModel: viewModel,
                storageAnalyzer: storageAnalyzer,
                photoAnalyzer: photoAnalyzer,
                contactAnalyzer: contactAnalyzer,
                batteryMonitor: batteryMonitor,
                privacyAuditor: privacyAuditor,
                permissionManager: permissionManager,
                onComplete: goForward
            )

        case .results:
            ResultsReportView(
                viewModel: viewModel,
                onContinue: goForward
            )

        case .personalPlan:
            PersonalPlanView(
                viewModel: viewModel,
                onContinue: goForward,
                onBack: goBack
            )

        case .honestAlternative:
            HonestAlternativeView(
                onContinue: goForward,
                onBack: goBack
            )

        case .paywall:
            PaywallOnboardingView(
                subscriptionManager: subscriptionManager,
                onContinue: goForward,
                onBack: goBack,
                onSkip: goForward
            )

        case .welcomeHome:
            WelcomeHomeView(
                viewModel: viewModel,
                dataManager: dataManager,
                appState: appState
            )
        }
    }

    // MARK: - Navigation

    private func goForward() {
        if let next = currentStep.next {
            currentStep = next
        }
    }

    private func goBack() {
        if let previous = currentStep.previous, currentStep.canGoBack {
            currentStep = previous
        }
    }
}
