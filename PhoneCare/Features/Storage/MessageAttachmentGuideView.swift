import SwiftUI

/// Guides users to review and clean up iMessage attachments via iOS Settings.
/// iMessage attachments aren't directly accessible via public APIs, so this
/// view educates users on how to find and clean them through Apple's built-in
/// storage management.
struct MessageAttachmentGuideView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: PCTheme.Spacing.lg) {
                // Header
                VStack(spacing: PCTheme.Spacing.md) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.pcAccent)
                        .voiceOverHidden()

                    Text("Messages can take up a lot of space")
                        .typography(.title2)
                        .multilineTextAlignment(.center)

                    Text("Photos and videos sent in iMessage are often the biggest hidden storage user on your iPhone. Apple doesn't show this clearly, but we can help you find them.")
                        .typography(.subheadline, color: .pcTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, PCTheme.Spacing.lg)

                // Step-by-step guide
                VStack(alignment: .leading, spacing: PCTheme.Spacing.md) {
                    Text("How to review message attachments")
                        .typography(.headline)

                    stepRow(
                        number: 1,
                        title: "Open Settings",
                        detail: "Tap the button below to go directly to your iPhone Storage settings."
                    )

                    stepRow(
                        number: 2,
                        title: "Find Messages",
                        detail: "Scroll down and tap \"Messages\" in the app list. It shows how much space your messages use."
                    )

                    stepRow(
                        number: 3,
                        title: "Review Large Attachments",
                        detail: "Tap \"Review Large Attachments\" to see photos and videos from your conversations, sorted by size."
                    )

                    stepRow(
                        number: 4,
                        title: "Delete what you don't need",
                        detail: "Swipe left on any attachment to delete it, or tap \"Edit\" to select multiple at once."
                    )
                }
                .padding(PCTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: PCTheme.Radius.lg)
                        .fill(Color.pcSurface)
                )

                // Open Settings button
                Button {
                    openStorageSettings()
                } label: {
                    HStack {
                        Image(systemName: "gear")
                        Text("Open iPhone Storage Settings")
                    }
                }
                .primaryCTAStyle()

                // Transparency note
                HStack(spacing: PCTheme.Spacing.sm) {
                    Image(systemName: "lock.shield.fill")
                        .font(.footnote)
                        .foregroundStyle(Color.pcTextSecondary)
                        .voiceOverHidden()

                    Text("PhoneCare cannot access your messages directly. This guide helps you use Apple's built-in tools to free up space safely.")
                        .typography(.footnote, color: .pcTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(PCTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: PCTheme.Radius.sm)
                        .fill(Color.pcSurface)
                )
                .accessibilityElement(children: .combine)
            }
            .padding(.horizontal, PCTheme.Spacing.md)
            .padding(.bottom, PCTheme.Spacing.xl)
        }
        .navigationTitle("Message Attachments")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Step Row

    private func stepRow(number: Int, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: PCTheme.Spacing.md) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.pcAccent))
                .voiceOverHidden()

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .typography(.subheadline)
                    .fontWeight(.semibold)
                Text(detail)
                    .typography(.footnote, color: .pcTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number): \(title). \(detail)")
    }

    // MARK: - Actions

    @MainActor
    private func openStorageSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
