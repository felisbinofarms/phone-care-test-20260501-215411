import SwiftUI
import StoreKit

struct AboutView: View {
    let appVersion: String
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(spacing: PCTheme.Spacing.lg) {
                // App icon and version
                VStack(spacing: PCTheme.Spacing.md) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.pcAccent)
                        .voiceOverHidden()

                    Text("PhoneCare")
                        .typography(.title2)

                    Text("Version \(appVersion)")
                        .typography(.footnote, color: .pcTextSecondary)
                }
                .padding(.top, PCTheme.Spacing.lg)

                // Links
                CardView {
                    VStack(spacing: 0) {
                        linkRow(icon: "doc.text", title: "Privacy Policy") {
                            if let url = PrivacyManifesto.privacyPolicyURL { openURL(url) }
                        }
                        .accessibilityIdentifier("about.privacyPolicy")

                        Divider().foregroundStyle(Color.pcBorder)

                        linkRow(icon: "doc.text", title: "Terms of Service") {
                            if let url = PrivacyManifesto.termsOfServiceURL { openURL(url) }
                        }
                        .accessibilityIdentifier("about.termsOfService")

                        Divider().foregroundStyle(Color.pcBorder)

                        linkRow(icon: "envelope", title: "Contact Support") {
                            if let url = URL(string: "mailto:support@phonecare.app") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .accessibilityIdentifier("about.contactSupport")

                        Divider().foregroundStyle(Color.pcBorder)

                        linkRow(icon: "star", title: "Rate PhoneCare") {
                            requestReview()
                        }
                        .accessibilityIdentifier("about.rateApp")
                    }
                }

                Text("Made with care for your phone.")
                    .typography(.footnote, color: .pcTextSecondary)
                    .padding(.bottom, PCTheme.Spacing.xl)
            }
            .padding(.horizontal, PCTheme.Spacing.md)
        }
        .background(Color.pcBackground)
        .accessibilityIdentifier("screen.about")
        .navigationTitle("About")
    }

    private func linkRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: PCTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(Color.pcPrimary)
                    .frame(width: 24)
                    .voiceOverHidden()

                Text(title)
                    .typography(.subheadline)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.footnote)
                    .foregroundStyle(Color.pcTextSecondary)
            }
            .padding(.vertical, PCTheme.Spacing.md)
        }
        .buttonStyle(.plain)
        .accessibleTapTarget()
    }

    private func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            return
        }

        AppStore.requestReview(in: scene)
    }
}
