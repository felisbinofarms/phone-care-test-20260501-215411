import SwiftUI

/// "My Year with PhoneCare" — a celebratory summary of what the user
/// accomplished over their subscription period. Designed to reinforce
/// value at renewal time.
struct AnnualReportView: View {

    let stats: CleanupStats

    var body: some View {
        ScrollView {
            VStack(spacing: PCTheme.Spacing.lg) {
                // Header
                VStack(spacing: PCTheme.Spacing.md) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.pcAccent)
                        .voiceOverHidden()

                    Text("Your Year with PhoneCare")
                        .typography(.title1)
                        .multilineTextAlignment(.center)

                    Text("Here's what we accomplished together.")
                        .typography(.subheadline, color: .pcTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, PCTheme.Spacing.lg)

                // Stats cards
                VStack(spacing: PCTheme.Spacing.md) {
                    statCard(
                        icon: "externaldrive.fill",
                        value: formattedBytes(stats.totalBytesFreed),
                        label: "space freed"
                    )

                    statCard(
                        icon: "photo.on.rectangle",
                        value: "\(stats.totalPhotosDeleted)",
                        label: "duplicate photos removed"
                    )

                    statCard(
                        icon: "person.2.fill",
                        value: "\(stats.totalContactsMerged)",
                        label: "contacts merged"
                    )

                    statCard(
                        icon: "lock.shield.fill",
                        value: "\(stats.totalPrivacyAudits)",
                        label: "privacy audits completed"
                    )

                    statCard(
                        icon: "magnifyingglass",
                        value: "\(stats.totalScans)",
                        label: "total scans"
                    )
                }

                // Value reminder
                CardView {
                    VStack(spacing: PCTheme.Spacing.sm) {
                        Text("Your subscription")
                            .typography(.headline)

                        Text("$19.99/year — that's about $0.05 per day")
                            .typography(.subheadline, color: .pcTextSecondary)

                        Text("Thank you for trusting PhoneCare to keep your phone running smoothly.")
                            .typography(.footnote, color: .pcTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, PCTheme.Spacing.xs)
                    }
                }

                // Member since
                if let dayCount = memberDays {
                    Text("PhoneCare member for \(dayCount) days")
                        .typography(.footnote, color: .pcTextSecondary)
                }
            }
            .padding(.horizontal, PCTheme.Spacing.md)
            .padding(.bottom, PCTheme.Spacing.xl)
        }
        .navigationTitle("Annual Report")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("screen.annualReport")
    }

    // MARK: - Stat Card

    private func statCard(icon: String, value: String, label: String) -> some View {
        CardView {
            HStack(spacing: PCTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Color.pcAccent)
                    .frame(width: 32)
                    .voiceOverHidden()

                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .typography(.title2)
                        .foregroundStyle(Color.pcAccent)

                    Text(label)
                        .typography(.subheadline, color: .pcTextSecondary)
                }

                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    // MARK: - Helpers

    private func formattedBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private var memberDays: Int? {
        let days = Calendar.current.dateComponents([.day], from: stats.firstUseDate, to: Date()).day
        guard let days, days > 0 else { return nil }
        return days
    }
}
