import SwiftUI

struct SettingsView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(AppState.self) private var appState
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: PCTheme.Spacing.lg) {
                // Subscription
                subscriptionSection

                // Appearance
                appearanceSection

                // Notifications
                notificationsSection

                // About
                aboutSection

                // Data & Privacy
                dataPrivacySection
            }
            .padding(.horizontal, PCTheme.Spacing.md)
            .padding(.top, PCTheme.Spacing.md)
            .padding(.bottom, PCTheme.Spacing.xl)
        }
        .background(Color.pcBackground)
        .navigationTitle("Settings")
        .onAppear {
            viewModel.load(dataManager: dataManager, appState: appState)
        }
    }

    // MARK: - Subscription

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: PCTheme.Spacing.sm) {
            Text("Subscription")
                .typography(.headline)
                .voiceOverHeading()

            SubscriptionStatusView()
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: PCTheme.Spacing.sm) {
            AppearancePickerView(
                selectedMode: $viewModel.appearanceMode,
                onChange: {
                    viewModel.saveAppearance(appState: appState)
                }
            )
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: PCTheme.Spacing.md) {
                Text("Notifications")
                    .typography(.headline)
                    .voiceOverHeading()

                Toggle("Weekly health check reminder", isOn: $viewModel.weeklyNotification)
                    .typography(.subheadline)
                    .tint(Color.pcAccent)
                    .onChange(of: viewModel.weeklyNotification) { _, _ in
                        viewModel.saveNotifications(dataManager: dataManager)
                    }

                Divider().foregroundStyle(Color.pcBorder)

                Toggle("Duplicate photo alerts", isOn: $viewModel.duplicateAlerts)
                    .typography(.subheadline)
                    .tint(Color.pcAccent)
                    .onChange(of: viewModel.duplicateAlerts) { _, _ in
                        viewModel.saveNotifications(dataManager: dataManager)
                    }

                Divider().foregroundStyle(Color.pcBorder)

                Toggle("Battery tips", isOn: $viewModel.batteryAlerts)
                    .typography(.subheadline)
                    .tint(Color.pcAccent)
                    .onChange(of: viewModel.batteryAlerts) { _, _ in
                        viewModel.saveNotifications(dataManager: dataManager)
                    }
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        NavigationLink {
            AboutView(appVersion: viewModel.appVersion)
        } label: {
            CardView {
                HStack(spacing: PCTheme.Spacing.md) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundStyle(Color.pcPrimary)
                        .voiceOverHidden()

                    VStack(alignment: .leading, spacing: PCTheme.Spacing.xs) {
                        Text("About PhoneCare")
                            .typography(.subheadline)

                        Text("Version \(viewModel.appVersion)")
                            .typography(.footnote, color: .pcTextSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(Color.pcTextSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Tap for app information, support, and legal links")
    }

    // MARK: - Data & Privacy

    private var dataPrivacySection: some View {
        NavigationLink {
            DataPrivacyView()
        } label: {
            CardView {
                HStack(spacing: PCTheme.Spacing.md) {
                    Image(systemName: "shield.checkered")
                        .font(.title3)
                        .foregroundStyle(Color.pcPrimary)
                        .voiceOverHidden()

                    VStack(alignment: .leading, spacing: PCTheme.Spacing.xs) {
                        Text(PrivacyManifesto.sectionTitle)
                            .typography(.subheadline)

                        Text(PrivacyManifesto.summaryText)
                            .typography(.footnote, color: .pcTextSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(Color.pcTextSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Tap to read your privacy details and manage your app data")
    }
}
