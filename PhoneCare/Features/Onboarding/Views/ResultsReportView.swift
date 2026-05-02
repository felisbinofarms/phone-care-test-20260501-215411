import SwiftUI

struct ResultsReportView: View {
    let viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var selectedDrillDown: ResultsDrillDown?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: PCTheme.Spacing.sm) {
                Text("Here is what we found")
                    .typography(.title1)

                Text("A quick look at your phone's health.")
                    .typography(.subheadline, color: .pcTextSecondary)
            }
            .padding(.horizontal, PCTheme.Spacing.md)
            .padding(.top, PCTheme.Spacing.lg)

            // Health score
            VStack(spacing: PCTheme.Spacing.xs) {
                Text("\(viewModel.scanResults.healthScore)")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .healthScoreColor(viewModel.scanResults.healthScore)

                Text("Health Score")
                    .typography(.footnote, color: .pcTextSecondary)
            }
            .padding(.top, PCTheme.Spacing.md)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Health score: \(viewModel.scanResults.healthScore) out of 100")

            // Result cards
            ScrollView {
                VStack(spacing: PCTheme.Spacing.sm) {
                    // Storage card
                    if let storage = viewModel.scanResults.storageResult {
                        ResultCard(
                            icon: "internaldrive.fill",
                            iconColor: .pcPrimary,
                            title: "Storage",
                            value: "\(Int(storage.usedPercentage))% used",
                            detail: "\(storage.formattedAvailable) available of \(storage.formattedTotal)",
                            isInteractive: true,
                            onTap: { selectedDrillDown = .storage }
                        )
                    }

                    // Photos card
                    if let photos = viewModel.scanResults.photoResult {
                        ResultCard(
                            icon: "photo.on.rectangle.fill",
                            iconColor: .pcAccent,
                            title: "Photos",
                            value: "\(photos.totalPhotos) photos",
                            detail: photos.duplicateCount > 0
                                ? "\(photos.duplicateCount) possible duplicates found"
                                : "No duplicates found",
                            isInteractive: true,
                            onTap: { selectedDrillDown = .photos }
                        )
                    }

                    // Contacts card
                    if let contacts = viewModel.scanResults.contactResult {
                        ResultCard(
                            icon: "person.2.fill",
                            iconColor: .pcPrimary,
                            title: "Contacts",
                            value: "\(contacts.totalContacts) contacts",
                            detail: contacts.duplicateCount > 0
                                ? "\(contacts.duplicateCount) possible duplicates found"
                                : "No duplicates found",
                            isInteractive: true,
                            onTap: { selectedDrillDown = .contacts }
                        )
                    }

                    // Battery card
                    if let battery = viewModel.scanResults.batteryInfo {
                        ResultCard(
                            icon: battery.levelIcon,
                            iconColor: .pcAccent,
                            title: "Battery",
                            value: "\(battery.levelPercentage)%",
                            detail: battery.state.displayName,
                            isInteractive: true,
                            onTap: { selectedDrillDown = .battery }
                        )
                    }

                    // Privacy card
                    if let privacy = viewModel.scanResults.privacyResult {
                        ResultCard(
                            icon: "lock.shield.fill",
                            iconColor: .pcPrimary,
                            title: "Privacy",
                            value: "\(privacy.privacyScore)/100",
                            detail: "\(privacy.reviewedCount) of \(privacy.summaries.count) permissions reviewed",
                            isInteractive: true,
                            onTap: { selectedDrillDown = .privacy }
                        )
                    }
                }
                .padding(.horizontal, PCTheme.Spacing.md)
                .padding(.top, PCTheme.Spacing.md)
                .padding(.bottom, PCTheme.Spacing.lg)
            }

            // CTA
            Button {
                onContinue()
            } label: {
                Text("See your plan")
            }
            .primaryCTAStyle()
            .padding(.horizontal, PCTheme.Spacing.lg)
            .padding(.bottom, PCTheme.Spacing.lg)
        }
        .sheet(item: $selectedDrillDown) { destination in
            NavigationStack {
                switch destination {
                case .storage:
                    StorageView()
                case .photos:
                    PhotosView()
                case .contacts:
                    ContactsView()
                case .battery:
                    BatteryView()
                case .privacy:
                    PrivacyView()
                }
            }
        }
    }
}

// MARK: - Result Card

private enum ResultsDrillDown: String, Identifiable {
    case storage
    case photos
    case contacts
    case battery
    case privacy

    var id: String { rawValue }
}

private struct ResultCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let detail: String
    let isInteractive: Bool
    let onTap: (() -> Void)?

    init(
        icon: String,
        iconColor: Color,
        title: String,
        value: String,
        detail: String,
        isInteractive: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.value = value
        self.detail = detail
        self.isInteractive = isInteractive
        self.onTap = onTap
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: PCTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                    .frame(width: 36, height: 36)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: PCTheme.Spacing.xs) {
                    HStack {
                        Text(title)
                            .typography(.headline)

                        Spacer()

                        Text(value)
                            .typography(.headline, color: .pcAccent)
                    }

                    Text(detail)
                        .typography(.subheadline, color: .pcTextSecondary)
                }

                if isInteractive {
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(Color.pcTextSecondary)
                        .padding(.leading, PCTheme.Spacing.xs)
                }
            }
            .padding(PCTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: PCTheme.Radius.lg)
                    .fill(Color.pcSurface)
                    .shadow(
                        color: PCTheme.Shadow.cardColor,
                        radius: PCTheme.Shadow.cardRadius,
                        x: PCTheme.Shadow.cardX,
                        y: PCTheme.Shadow.cardY
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!isInteractive)
        .accessibilityElement(children: .combine)
        .accessibilityHint(isInteractive ? "Double tap for details" : "Information")
    }
}
