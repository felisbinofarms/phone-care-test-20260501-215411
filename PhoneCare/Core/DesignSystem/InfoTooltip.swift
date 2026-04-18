import SwiftUI

/// A small info icon that, when tapped, shows a plain-English explanation
/// of a technical term in a popover. Designed for the 40+ audience to build
/// confidence and understanding.
struct InfoTooltip: View {
    let term: String
    let explanation: String

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: "info.circle")
                .font(.footnote)
                .foregroundStyle(Color.pcTextSecondary)
        }
        .accessibilityLabel("Learn more about \(term)")
        .accessibilityHint("Double tap to see a simple explanation")
        .popover(isPresented: $isPresented) {
            VStack(alignment: .leading, spacing: PCTheme.Spacing.sm) {
                Text(term)
                    .typography(.headline)

                Text(explanation)
                    .typography(.subheadline, color: .pcTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(PCTheme.Spacing.md)
            .frame(maxWidth: 300)
            .presentationCompactAdaptation(.popover)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Appends an info tooltip icon next to this view.
    func explainThis(_ term: String, explanation: String) -> some View {
        HStack(spacing: PCTheme.Spacing.xs) {
            self
            InfoTooltip(term: term, explanation: explanation)
        }
    }
}

// MARK: - Predefined Explanations

enum ExplainThisContent {
    static let storage = (
        term: "Storage",
        explanation: "The space on your phone where photos, apps, and messages are saved. When it fills up, your phone can slow down."
    )

    static let duplicatePhotos = (
        term: "Duplicate photos",
        explanation: "Photos that look the same or nearly the same — usually taken in burst mode or saved twice from a message."
    )

    static let batteryHealth = (
        term: "Battery health",
        explanation: "How much charge your battery can hold compared to when it was new. Over time, all batteries hold less charge."
    )

    static let limitedAccess = (
        term: "Limited access",
        explanation: "You've allowed PhoneCare to see only some of your photos, not all of them. You can change this in Settings."
    )

    static let privacyAudit = (
        term: "Privacy audit",
        explanation: "A check of which apps have permission to use your camera, microphone, location, and other parts of your phone."
    )

    static let permission = (
        term: "Permission",
        explanation: "An approval you gave an app to use a part of your phone, like the camera or contacts. You can change these anytime in Settings."
    )

    static let healthScore = (
        term: "Health score",
        explanation: "A number from 0 to 100 that shows how well your phone is doing overall — based on storage, photos, contacts, battery, and privacy."
    )

    static let optimizedCharging = (
        term: "Optimized Charging",
        explanation: "A setting that lets your iPhone learn your daily charging routine to slow down battery aging. Find it in Settings > Battery."
    )
}
