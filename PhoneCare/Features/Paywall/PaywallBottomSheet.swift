import SwiftUI

struct PaywallBottomSheet: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = PaywallViewModel()

    var contextualBenefit: String?
    @State private var showComparePlans = false

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.pcBorder)
                .frame(width: 36, height: 5)
                .padding(.top, PCTheme.Spacing.sm)
                .voiceOverHidden()

            ScrollView {
                VStack(spacing: PCTheme.Spacing.lg) {
                    // Header
                    headerSection

                    // Benefits
                    benefitsSection

                    // Product cards
                    productsSection

                    // Competitor comparison
                    competitorComparisonSection

                    // Compare plans (expandable)
                    comparePlansSection

                    // Error
                    if let error = viewModel.purchaseError {
                        Text(error)
                            .typography(.footnote, color: .pcWarning)
                            .multilineTextAlignment(.center)
                    }

                    // Purchase button
                    purchaseButton

                    // Restore + Legal
                    footerSection
                }
                .padding(.horizontal, PCTheme.Spacing.md)
                .padding(.top, PCTheme.Spacing.lg)
                .padding(.bottom, PCTheme.Spacing.xl)
            }
        }
        .background(Color.pcBackground)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .task {
            await viewModel.load(subscriptionManager: subscriptionManager)
            viewModel.recordShown()
        }
        .onChange(of: viewModel.purchaseComplete) { _, complete in
            if complete { dismiss() }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: PCTheme.Spacing.md) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.pcAccent)
                .voiceOverHidden()

            Text("Unlock PhoneCare Premium")
                .typography(.title2)
                .multilineTextAlignment(.center)

            if let benefit = contextualBenefit {
                Text(benefit)
                    .typography(.subheadline, color: .pcTextSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Get the most out of your phone with full access to all features.")
                    .typography(.subheadline, color: .pcTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Benefits

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: PCTheme.Spacing.sm) {
            benefitRow(icon: "photo.on.rectangle", text: "Unlimited photo cleanup")
            benefitRow(icon: "person.2", text: "Full contact merging")
            benefitRow(icon: "chart.xyaxis.line", text: "Extended battery history")
            benefitRow(icon: "wand.and.stars", text: "Guided cleanup wizards")
            benefitRow(icon: "bell.badge", text: "Smart notifications")
        }
        .padding(.vertical, PCTheme.Spacing.sm)
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: PCTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.pcAccent)
                .frame(width: 24)
                .voiceOverHidden()

            Text(text)
                .typography(.subheadline)

            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Products

    private var productsSection: some View {
        HStack(spacing: PCTheme.Spacing.sm) {
            ForEach(viewModel.products, id: \.id) { product in
                ProductCardView(
                    product: product,
                    isSelected: viewModel.selectedProduct?.id == product.id,
                    savingsLabel: viewModel.savingsLabel(for: product),
                    trialLabel: viewModel.trialLabel(for: product),
                    periodLabel: subscriptionManager.periodLabel(for: product),
                    weeklyEquivalentLabel: viewModel.weeklyEquivalentLabel(for: product),
                    onSelect: { viewModel.selectedProduct = product }
                )
            }
        }
    }

    // MARK: - Competitor Comparison

    private var competitorComparisonSection: some View {
        HStack(spacing: PCTheme.Spacing.sm) {
            Image(systemName: "info.circle.fill")
                .font(.footnote)
                .foregroundStyle(Color.pcTextSecondary)
                .accessibilityHidden(true)

            Text("Popular cleaner apps charge $415/year. PhoneCare is $19.99.")
                .typography(.footnote, color: .pcTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(PCTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: PCTheme.Radius.sm)
                .fill(Color.pcSurface)
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Compare Plans

    private var comparePlansSection: some View {
        VStack(alignment: .leading, spacing: PCTheme.Spacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showComparePlans.toggle()
                }
            } label: {
                HStack {
                    Text("Compare plans")
                        .typography(.subheadline, color: .pcPrimary)
                    Spacer()
                    Image(systemName: showComparePlans ? "chevron.up" : "chevron.down")
                        .font(.footnote)
                        .foregroundStyle(Color.pcTextSecondary)
                }
            }
            .accessibilityHint(showComparePlans ? "Collapse plan comparison" : "Expand plan comparison")

            if showComparePlans {
                VStack(spacing: PCTheme.Spacing.xs) {
                    HStack {
                        Text("Plan")
                            .typography(.caption, color: .pcTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Per year")
                            .typography(.caption, color: .pcTextSecondary)
                    }
                    Divider()
                    ForEach(viewModel.products, id: \.id) { product in
                        HStack {
                            Text(subscriptionManager.periodLabel(for: product).capitalized)
                                .typography(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(viewModel.annualCostLabel(for: product) ?? product.displayPrice)
                                .typography(.subheadline, color: .pcAccent)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(PCTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: PCTheme.Radius.sm)
                        .fill(Color.pcSurface)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            Task {
                await viewModel.purchase(subscriptionManager: subscriptionManager)
            }
        } label: {
            if viewModel.isPurchasing {
                ProgressView()
                    .tint(.white)
            } else {
                Text(purchaseButtonTitle)
            }
        }
        .primaryCTAStyle()
        .disabled(viewModel.isPurchasing || viewModel.selectedProduct == nil)
    }

    private var purchaseButtonTitle: String {
        guard let product = viewModel.selectedProduct else { return "Select a Plan" }
        if viewModel.hasFreeTrial(for: product) {
            return "Start Free Trial"
        }
        return "Subscribe for \(product.displayPrice)"
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: PCTheme.Spacing.sm) {
            Button("Restore Purchases") {
                Task {
                    await viewModel.restore(subscriptionManager: subscriptionManager)
                }
            }
            .textLinkStyle()
            .accessibleTapTarget()

            Text("Payment will be charged to your Apple ID. Subscription automatically renews unless canceled at least 24 hours before the end of the current period.")
                .typography(.caption, color: .pcTextSecondary)
                .multilineTextAlignment(.center)

            HStack(spacing: PCTheme.Spacing.md) {
                Button("Terms of Use") {
                    // Open terms URL
                }
                .textLinkStyle()
                .font(.caption)

                Button("Privacy Policy") {
                    // Open privacy URL
                }
                .textLinkStyle()
                .font(.caption)
            }

            // Dismiss
            Button("Not Now") {
                dismiss()
            }
            .textLinkStyle()
            .accessibleTapTarget()
            .padding(.top, PCTheme.Spacing.sm)
        }
    }
}
