---
name: storekit2-integration
user-invocable: true
description: "Use when: implementing subscriptions, payment flows, trial management, receipt validation, Restore Purchases button, testing in sandbox, App Store compliance for billing."
---

# PhoneCare StoreKit 2 Integration Skill

Complete guide to implementing subscriptions using StoreKit 2 (no RevenueCat or third-party wrappers).

## StoreKit 2 Overview

**Why StoreKit 2?**
- Native Apple framework (iOS 17+)
- Simpler API than StoreKit 1
- Direct receipt validation (no RevenueCat)
- App Store review: clearer billing disclosure
- PhoneCare: 100% on-device, no backend → receipts stored locally only

## Subscription Products

**PhoneCare Subscription Tiers:**

| Product ID | Duration | Price | Trial | Notes |
|-----------|----------|-------|-------|-------|
| `com.phonecare.sub.weekly` | 1 week | $0.99/week | 7 days | Entry-level |
| `com.phonecare.sub.monthly` | 1 month | $2.99/month | 7 days | Alternative |
| `com.phonecare.sub.annual` | 1 year | $19.99/year | 7 days | **DEFAULT** |

**Setup in App Store Connect:**
1. Go to your app in App Store Connect
2. Pricing, Scheduling → Subscription Groups
3. Create group "PhoneCareSubscriptions"
4. Add 3 products with trial durations
5. Enable automatic renewal messaging

## SubscriptionManager Implementation

```swift
import StoreKit

@Observable
final class SubscriptionManager: NSObject {
    @MainActor var products: [Product] = []
    @MainActor var purchasedProductIDs: Set<String> = []
    @MainActor var loadingState: LoadingState = .idle
    @MainActor var isSubscribed: Bool = false
    
    private var updates: Task<Void, Never>?
    
    override init() {
        super.init()
        setupPurchaseUpdates()
    }
    
    deinit {
        updates?.cancel()
    }
    
    // MARK: - Load Products
    
    @MainActor
    func loadProducts() async {
        loadingState = .loading
        do {
            let productIDs = [
                "com.phonecare.sub.weekly",
                "com.phonecare.sub.monthly",
                "com.phonecare.sub.annual"
            ]
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }  // Cheapest first
            loadingState = .success
        } catch {
            loadingState = .error(error)
        }
    }
    
    // MARK: - Purchase
    
    @MainActor
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // Verify signature
            let transaction = try verification.payloadValue
            purchasedProductIDs.insert(transaction.productID)
            isSubscribed = true
            await transaction.finish()  // Mark consumed
            
        case .userCancelled:
            // User cancelled - no error
            break
            
        case .pending:
            // Waiting for family request approval
            break
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Restore Purchases
    
    @MainActor
    func restorePurchases() async {
        loadingState = .loading
        do {
            purchasedProductIDs.removeAll()
            for await result in Transaction.currentEntitlements {
                let transaction = try result.payloadValue
                purchasedProductIDs.insert(transaction.productID)
                isSubscribed = !purchasedProductIDs.isEmpty
            }
            loadingState = .success
        } catch {
            loadingState = .error(error)
        }
    }
    
    // MARK: - Check Subscription Status
    
    @MainActor
    func checkSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            let transaction = try? result.payloadValue
            if let tx = transaction, tx.revocationDate == nil {
                purchasedProductIDs.insert(tx.productID)
            }
        }
        isSubscribed = !purchasedProductIDs.isEmpty
    }
    
    // MARK: - Setup Purchase Updates (Listen for new purchases)
    
    private func setupPurchaseUpdates() {
        updates = Task {
            for await result in Transaction.updates {
                let transaction = try? result.payloadValue
                if let tx = transaction {
                    switch tx.revocationDate {
                    case .none:
                        // Purchase valid
                        await MainActor.run {
                            purchasedProductIDs.insert(tx.productID)
                            isSubscribed = true
                        }
                    default:
                        // Purchase revoked
                        await MainActor.run {
                            purchasedProductIDs.remove(tx.productID)
                            isSubscribed = !purchasedProductIDs.isEmpty
                        }
                    }
                    await transaction.finish()
                }
            }
        }
    }
}
```

## Paywall View Implementation

```swift
struct PaywallView: View {
    @State var subscriptionManager = SubscriptionManager()
    @State var selectedProduct: Product?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .lg) {
                    // Header
                    VStack(alignment: .leading, spacing: .sm) {
                        Text("Go Premium")
                            .font(.headline)
                        
                        Text("Unlock full cleanup power")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.bottom, .md)
                    
                    // Feature List
                    VStack(alignment: .leading, spacing: .sm) {
                        FeatureRow(text: "Batch delete photos")
                        FeatureRow(text: "Merge duplicate contacts")
                        FeatureRow(text: "Detailed battery trends")
                    }
                    
                    Spacer(minLength: .xl)
                    
                    // Product Selection
                    if !subscriptionManager.products.isEmpty {
                        VStack(spacing: .sm) {
                            ForEach(subscriptionManager.products, id: \.id) { product in
                                ProductRowView(
                                    product: product,
                                    isSelected: selectedProduct?.id == product.id,
                                    action: { selectedProduct = product }
                                )
                            }
                        }
                    }
                    
                    Spacer(minLength: .xl)
                    
                    // Trial Info (REQUIRED for App Store)
                    Text("7-day free trial, then \\(selectedProduct?.displayPrice ?? "$0.00")/\\(selectedProduct?.subscription?.period.description ?? "month"). Cancel anytime in Settings.")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .padding(.all, .sm)
                        .background(Color.surface)
                        .cornerRadius(.md)
                    
                    // Purchase Button
                    if let selectedProduct {
                        Button(action: { purchaseSelected() }) {
                            Text("Start Free Trial")
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.accent)
                                .foregroundColor(.white)
                                .cornerRadius(.md)
                        }
                    }
                    
                    // Not Now Button (REQUIRED - user must be able to dismiss)
                    Button(action: { dismiss() }) {
                        Text("Not Now")
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.surface)
                            .foregroundColor(.textPrimary)
                            .cornerRadius(.md)
                    }
                }
                .padding(.all, .lg)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            Task { await subscriptionManager.loadProducts() }
        }
    }
    
    private func purchaseSelected() {
        guard let product = selectedProduct else { return }
        
        Task {
            do {
                try await subscriptionManager.purchase(product)
                dismiss()  // Close paywall after purchase
            } catch {
                // Handle error
            }
        }
    }
}

struct ProductRowView: View {
    let product: Product
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: .xs) {
                    Text(product.displayName)
                        .font(.body)
                        .foregroundColor(.textPrimary)
                    
                    // Trial badge
                    if product.subscription?.trialPeriod != nil {
                        Text("7 days free")
                            .font(.caption)
                            .foregroundColor(.accent)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: .xs) {
                    Text(product.displayPrice)
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    Text("per \\(product.subscription?.period.description ?? "month")")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accent : .textSecondary)
            }
            .padding(.all, .md)
            .background(isSelected ? Color.accent.opacity(0.1) : Color.surface)
            .cornerRadius(.md)
            .overlay(
                RoundedRectangle(cornerRadius: .md)
                    .stroke(isSelected ? Color.accent : Color.clear, lineWidth: 2)
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(product.displayName): \(product.displayPrice)")
    }
}
```

## Restore Purchases Button (Required by Apple)

**Location:** Settings tab, clearly visible

```swift
struct SettingsView: View {
    @State var subscriptionManager = SubscriptionManager()
    
    var body: some View {
        List {
            // ... other settings
            
            Section("Subscription") {
                Button(action: restorePurchases) {
                    Text("Restore Purchases")
                }
                
                if subscriptionManager.isSubscribed {
                    Text("✓ Premium active")
                        .foregroundColor(.accent)
                }
            }
        }
    }
    
    private func restorePurchases() {
        Task {
            await subscriptionManager.restorePurchases()
        }
    }
}
```

## Sandbox Testing (CRITICAL for App Store Review)

### Setup Sandbox Account

1. App Store Connect → Users and Access → Sandboxes → Users
2. Create test account with email (e.g., `phonecare-test@example.com`)
3. Set password, country
4. On device: iOS Settings → App Store → Sign Out
5. When app tries purchase: Sign in with sandbox account

### Test Scenarios

| Scenario | Steps | Expected |
|----------|-------|----------|
| Purchase Annual | Tap product, confirm | "7-day trial" screen, then access unlocked |
| Trial expires | Fast-forward device clock 7 days | Access revoked, paywall shows |
| Restore | In Settings, tap Restore | Access re-granted |
| Trial re-purchase | Cancel sub, repurchase | New 7-day trial granted |
| Free trial complete | Wait 7 days, don't convert to paid | Access expires, "Restore" button shows |

### Sandbox Gotchas

- **Clock matters:** Test fast-forwards device clock
- **Sandbox account only:** Use sandbox email during testing
- **No real charges:** All transactions are simulated
- **Test environment separate:** Sandbox purchases don't affect production

## Receipt Validation (Local-Only for MVP)

**PhoneCare MVP:** No backend → validate receipts locally

```swift
// Simple validation: Check transaction.revocationDate
// For production with backend, implement full receipt verification

@MainActor
func isUserPremium() -> Bool {
    // In local-only MVP: check purchasedProductIDs
    return !subscriptionManager.purchasedProductIDs.isEmpty
}

@MainActor
func canAccessPremiumFeature() -> Bool {
    return isUserPremium()
}
```

## App Store Compliance Checklist

Before submitting to App Store:

- [ ] **Trial disclosed:** "7-day free trial" shown before purchase
- [ ] **Renewal terms:** "Renews automatically. Cancel anytime in Settings." visible
- [ ] **Cancellation clear:** Link to Settings app for subscription management
- [ ] **Restore button:** Easy to find in Settings
- [ ] **All prices shown:** Annual, monthly, weekly all visible
- [ ] **No "Required":** Never force subscription before trying feature
- [ ] **Close button on paywall:** User can dismiss and continue using free features
- [ ] **Transparent pricing:** No hidden fees or confusing language
- [ ] **Sandbox testing:** QA tested with sandbox account
- [ ] **Privacy:** No unexpected permission requests

## Edge Cases & Solutions

| Case | Solution |
|------|----------|
| User purchases, then jailbreaks device | No control - accept loss. Receipts tampered. |
| Network fails during purchase | StoreKit handles retry. App just waits. |
| User has multiple subscriptions | Check `currentEntitlements` - take first active |
| Refund issued by Apple | `revocationDate` set - revoke access |
| Device clock set to future | Trial expires immediately - accept clock |
| Subscription lapses due to expired payment method | `revocationDate` set - show resubscribe CTA |

## Output Format

When implementing StoreKit 2:

```markdown
## Subscription Implementation: [Feature]

### Products
- [ ] `com.phonecare.sub.weekly` ($0.99, 7-day trial)
- [ ] `com.phonecare.sub.monthly` ($2.99, 7-day trial)
- [ ] `com.phonecare.sub.annual` ($19.99, 7-day trial)

### Paywall UX
- [ ] Trial terms visible: "7-day free, then $19.99/year"
- [ ] "Not now" button visible and functional
- [ ] Product selection UI clear
- [ ] Pricing displayed for all products

### Restore Purchases
- [ ] Button in Settings, easy to find
- [ ] Works for already-purchased subscriptions
- [ ] Shows status: "Premium active" or "No active subscription"

### Sandbox Testing
- [ ] Tested with sandbox account
- [ ] Trial grants access immediately
- [ ] Clock fast-forward: trial expires correctly
- [ ] Restore Purchases works in sandbox

### Compliance
- [ ] All pricing transparent
- [ ] No paywall before feature value
- [ ] Clear renewal and cancellation
- [ ] Matches App Store requirements
```

---

**Use This Skill When:**
- Implementing paywall or subscription flow
- Testing billing in sandbox
- Validating App Store compliance
- Troubleshooting purchase failures
- Reviewing subscription manager code
