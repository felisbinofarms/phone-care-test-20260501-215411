import SwiftUI
import StoreKit

struct PaywallOnboardingView: View {
    let subscriptionManager: SubscriptionManager
    let onContinue: () -> Void
    let onSkip: () -> Void

    @Environment(\.openURL) private var openURL
    @State private var selectedProductID: String?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: PCTheme.Spacing.lg) {
                    // Header
                    VStack(spacing: PCTheme.Spacing.sm) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.pcAccent)
                            .accessibilityHidden(true)

                        Text("Unlock the full experience")
                            .typography(.title1)
                            .multilineTextAlignment(.center)

                        Text("Get the most out of PhoneCare with premium features.")
                            .typography(.subheadline, color: .pcTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, PCTheme.Spacing.lg)

                    // Benefits
                    VStack(alignment: .leading, spacing: PCTheme.Spacing.md) {
                        BenefitRow(icon: "photo.on.rectangle.fill", text: "Unlimited duplicate photo cleanup")
                        BenefitRow(icon: "person.2.fill", text: "Automatic contact merging")
                        BenefitRow(icon: "chart.line.uptrend.xyaxis", text: "Battery health tracking over time")
                        BenefitRow(icon: "lock.shield.fill", text: "Full privacy audit and tips")
                        BenefitRow(icon: "bell.fill", text: "Smart reminders to keep your phone healthy")
                    }
                    .padding(.horizontal, PCTheme.Spacing.md)

                    // Plan options
                    VStack(spacing: PCTheme.Spacing.sm) {
                        ForEach(sortedProducts, id: \.id) { product in
                            PlanOptionRow(
                                product: product,
                                periodLabel: subscriptionManager.periodLabel(for: product),
                                isSelected: selectedProductID == product.id,
                                isRecommended: isAnnual(product)
                            ) {
                                selectedProductID = product.id
                            }
                        }
                    }
                    .padding(.horizontal, PCTheme.Spacing.md)
                }
                .padding(.horizontal, PCTheme.Spacing.md)
            }

            // Bottom actions
            VStack(spacing: PCTheme.Spacing.md) {
                // Purchase CTA
                Button {
                    Task { await handlePurchase() }
                } label: {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Start free trial")
                    }
                }
                .primaryCTAStyle()
                .disabled(selectedProductID == nil || isPurchasing)

                // Not now -- ALWAYS visible, same size as CTA
                Button {
                    onSkip()
                } label: {
                    Text("Not now")
                }
                .textLinkStyle()
                .frame(minHeight: PCTheme.HitArea.primaryCTA)

                // Restore + Terms
                HStack(spacing: PCTheme.Spacing.md) {
                    Button("Restore Purchases") {
                        Task {
                            await subscriptionManager.restorePurchases()
                            if subscriptionManager.isPremium {
                                onContinue()
                            }
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(Color.pcTextSecondary)

                    Text("|")
                        .font(.caption)
                        .foregroundStyle(Color.pcBorder)

                    Button("Terms") {
                        openURL(URL(string: "https://pyroforbes.github.io/phone-care-ios/terms")!)
                    }
                    .font(.caption)
                    .foregroundStyle(Color.pcTextSecondary)

                    Text("|")
                        .font(.caption)
                        .foregroundStyle(Color.pcBorder)

                    Button("Privacy") {
                        openURL(URL(string: "https://pyroforbes.github.io/phone-care-ios/privacy")!)
                    }
                    .font(.caption)
                    .foregroundStyle(Color.pcTextSecondary)
                }
                .padding(.bottom, PCTheme.Spacing.sm)
            }
            .padding(.horizontal, PCTheme.Spacing.lg)
            .padding(.bottom, PCTheme.Spacing.md)
        }
        .task {
            if subscriptionManager.products.isEmpty {
                await subscriptionManager.loadProducts()
            }
            // Pre-select annual plan
            selectedProductID = sortedProducts.first(where: { isAnnual($0) })?.id
                ?? sortedProducts.last?.id
        }
        .alert("Something went wrong", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Helpers

    private var sortedProducts: [Product] {
        subscriptionManager.products.sorted { $0.price < $1.price }
    }

    private func isAnnual(_ product: Product) -> Bool {
        product.subscription?.subscriptionPeriod.unit == .year
    }

    private func handlePurchase() async {
        guard let productID = selectedProductID,
              let product = subscriptionManager.products.first(where: { $0.id == productID }) else {
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let transaction = try await subscriptionManager.purchase(product)
            if transaction != nil {
                onContinue()
            }
        } catch {
            errorMessage = "We could not complete your purchase. Please try again."
            showError = true
        }
    }
}

// MARK: - Benefit Row

private struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: PCTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.pcAccent)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(text)
                .typography(.body)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Plan Option Row

private struct PlanOptionRow: View {
    let product: Product
    let periodLabel: String
    let isSelected: Bool
    let isRecommended: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: PCTheme.Spacing.md) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.pcAccent : Color.pcBorder)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: PCTheme.Spacing.sm) {
                        Text(periodLabel.capitalized)
                            .typography(.headline)

                        if isRecommended {
                            Text("Best Value")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, PCTheme.Spacing.sm)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.pcAccent))
                        }
                    }
                }

                Spacer()

                Text(product.displayPrice)
                    .typography(.headline, color: .pcAccent)
            }
            .padding(PCTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: PCTheme.Radius.md)
                    .fill(isSelected ? Color.pcMintTint : Color.pcSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: PCTheme.Radius.md)
                    .strokeBorder(
                        isSelected ? Color.pcAccent : Color.pcBorder,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(periodLabel) plan, \(product.displayPrice)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint(isRecommended ? "Best value" : "")
    }
}
