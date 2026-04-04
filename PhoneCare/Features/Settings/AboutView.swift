import SwiftUI

enum PhoneCareLegalLinks {
    static let termsOfUse = URL(string: "https://pyroforbes.github.io/phone-care-ios/terms")
    static let privacyPolicy = URL(string: "https://pyroforbes.github.io/phone-care-ios/privacy")
}

struct AboutView: View {
    @Environment(\.openURL) private var openURL
    let appVersion: String

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
                            if let url = PhoneCareLegalLinks.privacyPolicy {
                                openURL(url)
                            }
                        }

                        Divider().foregroundStyle(Color.pcBorder)

                        linkRow(icon: "doc.text", title: "Terms of Use") {
                            if let url = PhoneCareLegalLinks.termsOfUse {
                                openURL(url)
                            }
                        }

                        Divider().foregroundStyle(Color.pcBorder)

                        linkRow(icon: "envelope", title: "Contact Support") {
                            if let url = URL(string: "mailto:support@phonecare.app") {
                                UIApplication.shared.open(url)
                            }
                        }

                        Divider().foregroundStyle(Color.pcBorder)

                        linkRow(icon: "star", title: "Rate PhoneCare") {
                            // Open App Store review URL
                        }
                    }
                }

                Text("Made with care for your phone.")
                    .typography(.footnote, color: .pcTextSecondary)
                    .padding(.bottom, PCTheme.Spacing.xl)
            }
            .padding(.horizontal, PCTheme.Spacing.md)
        }
        .background(Color.pcBackground)
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
}
