import SwiftUI

struct DataPrivacyView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL
    @State private var showFirstConfirmation = false
    @State private var showFinalConfirmation = false
    @State private var isDeleting = false
    @State private var deleteComplete = false

    var body: some View {
        ScrollView {
            VStack(spacing: PCTheme.Spacing.lg) {
                // Info section
                CardView {
                    VStack(alignment: .leading, spacing: PCTheme.Spacing.md) {
                        HStack(spacing: PCTheme.Spacing.md) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.title2)
                                .foregroundStyle(Color.pcAccent)
                                .voiceOverHidden()

                            Text(PrivacyManifesto.sectionTitle)
                                .typography(.headline)
                        }

                        Text(PrivacyManifesto.detailsText)
                            .typography(.subheadline, color: .pcTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        noTrackersBadge

                        VStack(alignment: .leading, spacing: PCTheme.Spacing.sm) {
                            ForEach(PrivacyManifesto.noCollectionPoints, id: \.self) { item in
                                privacyPoint(item)
                            }
                        }

                        appStoreLabelCard

                        if let policyURL = PrivacyManifesto.privacyPolicyURL {
                            Button {
                                openURL(policyURL)
                            } label: {
                                Label("Read Privacy Policy", systemImage: "doc.text")
                            }
                            .secondaryStyle()
                            .accessibilityHint("Opens the full privacy policy")
                        }
                    }
                }

                // Delete section
                CardView {
                    VStack(alignment: .leading, spacing: PCTheme.Spacing.md) {
                        Text("Delete All Data")
                            .typography(.headline)
                            .voiceOverHeading()

                        Text("This will permanently delete all scan history, preferences, and cached data from PhoneCare. Your photos, contacts, and other phone data are not affected.")
                            .typography(.subheadline, color: .pcTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if deleteComplete {
                            HStack(spacing: PCTheme.Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.pcAccent)
                                Text("All data has been deleted.")
                                    .typography(.subheadline, color: .pcAccent)
                            }
                        } else {
                            Button("Delete All PhoneCare Data") {
                                showFirstConfirmation = true
                            }
                            .destructiveStyle()
                            .disabled(isDeleting)
                        }
                    }
                }
            }
            .padding(.horizontal, PCTheme.Spacing.md)
            .padding(.top, PCTheme.Spacing.md)
            .padding(.bottom, PCTheme.Spacing.xl)
        }
        .background(Color.pcBackground)
        .navigationTitle("Data & Privacy")
        .alert("Delete all data?", isPresented: $showFirstConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Continue", role: .destructive) {
                showFinalConfirmation = true
            }
        } message: {
            Text("This will remove all PhoneCare data from your device. This cannot be undone.")
        }
        .alert("Are you sure?", isPresented: $showFinalConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Everything", role: .destructive) {
                performDelete()
            }
        } message: {
            Text("This is your last chance. All scan history, preferences, and cached data will be permanently deleted.")
        }
    }

    private func privacyPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: PCTheme.Spacing.sm) {
            Image(systemName: "checkmark.shield.fill")
                .font(.footnote)
                .foregroundStyle(Color.pcAccent)
                .voiceOverHidden()

            Text(text)
                .typography(.footnote, color: .pcTextSecondary)
        }
    }

    private var noTrackersBadge: some View {
        HStack(spacing: PCTheme.Spacing.sm) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(Color.pcAccent)
                .voiceOverHidden()
            Text("No Trackers")
                .typography(.subheadline, color: .pcAccent)
                .accessibilityLabel("No Trackers badge")
        }
        .padding(.horizontal, PCTheme.Spacing.sm)
        .padding(.vertical, PCTheme.Spacing.xs)
        .background(
            Capsule()
                .fill(Color.pcAccent.opacity(0.12))
        )
    }

    private var appStoreLabelCard: some View {
        VStack(alignment: .leading, spacing: PCTheme.Spacing.xs) {
            Text(PrivacyManifesto.appStoreLabelTitle)
                .typography(.footnote, color: .pcTextSecondary)
            Text(PrivacyManifesto.appStoreLabelValue)
                .typography(.subheadline, color: .pcTextPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PCTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: PCTheme.Radius.sm)
                .fill(Color.pcMintTint)
        )
        .accessibilityElement(children: .combine)
    }

    private func performDelete() {
        isDeleting = true
        do {
            try dataManager.deleteAllData()
            deleteComplete = true
        } catch {
            // Show error if needed
        }
        isDeleting = false
    }
}
