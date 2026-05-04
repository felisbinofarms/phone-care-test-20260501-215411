import SwiftUI

/// Non-intrusive referral screen accessible from Settings.
/// Allows users to share PhoneCare with friends via the system share sheet.
/// No pressure, no popups — fully user-initiated.
struct GiftAFriendView: View {

    @State private var showShareSheet = false

    private let appStoreURL = "https://apps.apple.com/app/phonecare/id0000000000"

    var body: some View {
        ScrollView {
            VStack(spacing: PCTheme.Spacing.lg) {
                // Header
                VStack(spacing: PCTheme.Spacing.md) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.pcAccent)
                        .voiceOverHidden()

                    Text("Share PhoneCare with someone you care about")
                        .typography(.title2)
                        .multilineTextAlignment(.center)

                    Text("Know someone frustrated by slow phones or scam cleaner apps? Send them PhoneCare — honest phone maintenance at a fair price.")
                        .typography(.subheadline, color: .pcTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, PCTheme.Spacing.lg)

                // Value props
                VStack(alignment: .leading, spacing: PCTheme.Spacing.md) {
                    valueRow(icon: "shield.checkered", text: "No scam alerts or fake warnings")
                    valueRow(icon: "dollarsign.circle", text: "$19.99/year — not $400+ like competitors")
                    valueRow(icon: "lock.fill", text: "100% on-device — no data leaves their phone")
                    valueRow(icon: "hand.thumbsup.fill", text: "Built for people who want honest help")
                }
                .padding(PCTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: PCTheme.Radius.lg)
                        .fill(Color.pcSurface)
                )

                // Share button
                Button {
                    showShareSheet = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share PhoneCare")
                    }
                }
                .primaryCTAStyle()

                // Calm reassurance
                Text("We'll never send anything on your behalf. You're just sharing a link.")
                    .typography(.footnote, color: .pcTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, PCTheme.Spacing.md)
            .padding(.bottom, PCTheme.Spacing.xl)
        }
        .navigationTitle("Share with a Friend")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("screen.giftAFriend")
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareMessage])
        }
    }

    // MARK: - Value Row

    private func valueRow(icon: String, text: String) -> some View {
        HStack(spacing: PCTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.pcAccent)
                .frame(width: 24)
                .voiceOverHidden()

            Text(text)
                .typography(.subheadline)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Share Content

    private var shareMessage: String {
        "I use PhoneCare to keep my iPhone running smoothly — no scam alerts, just honest phone maintenance. It's $19.99/year (competitors charge $400+). Check it out: \(appStoreURL)"
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Promo Frequency Manager

enum PromoFrequencyManager {
    private static let lastShownKey = "PromoLastShownDate"
    private static let optOutKey = "PromoOptOut"
    private static let minimumInterval: TimeInterval = 30 * 24 * 3600 // 30 days

    static var isOptedOut: Bool {
        get { UserDefaults.standard.bool(forKey: optOutKey) }
        set { UserDefaults.standard.set(newValue, forKey: optOutKey) }
    }

    static var canShowPromo: Bool {
        guard !isOptedOut else { return false }
        guard let lastShown = UserDefaults.standard.object(forKey: lastShownKey) as? Date else {
            return true
        }
        return Date().timeIntervalSince(lastShown) >= minimumInterval
    }

    static func recordShown() {
        UserDefaults.standard.set(Date(), forKey: lastShownKey)
    }
}
