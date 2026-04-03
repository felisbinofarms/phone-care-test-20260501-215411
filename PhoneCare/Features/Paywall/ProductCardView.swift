import SwiftUI
import StoreKit

struct ProductCardView: View {
    let product: Product
    let isSelected: Bool
    let savingsLabel: String?
    let trialLabel: String?
    let periodLabel: String
    var onSelect: (() -> Void)?
    var weeklyEquivalentLabel: String?

    var body: some View {
        Button {
            onSelect?()
        } label: {
            VStack(spacing: PCTheme.Spacing.sm) {
                // Savings / Trial badge
                if let badge = savingsLabel ?? trialLabel {
                    Text(badge)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, PCTheme.Spacing.sm)
                        .padding(.vertical, PCTheme.Spacing.xs)
                        .background(Capsule().fill(Color.pcAccent))
                }

                // Price
                Text(product.displayPrice)
                    .typography(.title2)

                // Period
                Text("per \(periodLabel)")
                    .typography(.footnote, color: .pcTextSecondary)

                // Weekly equivalent (annual plans only)
                if let weekly = weeklyEquivalentLabel {
                    Text(weekly)
                        .typography(.caption, color: .pcTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PCTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: PCTheme.Radius.md)
                    .fill(isSelected ? Color.pcMintTint : Color.pcSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: PCTheme.Radius.md)
                            .strokeBorder(isSelected ? Color.pcAccent : Color.pcBorder, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibleTapTarget()
        .accessibilityLabel("\(product.displayPrice) per \(periodLabel)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Double tap to select this plan")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
