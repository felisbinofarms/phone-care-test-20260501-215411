import Testing
import Foundation
@testable import PhoneCare

@Suite("SubscriptionManager")
@MainActor
struct SubscriptionManagerTests {

    // MARK: - ProductID enum

    @Test("ProductID.allCases contains exactly 3 products")
    func productID_allCases_count() {
        #expect(SubscriptionManager.ProductID.allCases.count == 3)
    }

    @Test("ProductID raw values match the expected App Store product identifiers")
    func productID_rawValues() {
        #expect(SubscriptionManager.ProductID.weekly.rawValue == "com.phonecare.premium.weekly")
        #expect(SubscriptionManager.ProductID.monthly.rawValue == "com.phonecare.premium.monthly")
        #expect(SubscriptionManager.ProductID.annual.rawValue == "com.phonecare.premium.annual")
    }

    @Test("ProductID can be initialised from a known raw value")
    func productID_initFromRawValue() {
        #expect(SubscriptionManager.ProductID(rawValue: "com.phonecare.premium.annual") == .annual)
        #expect(SubscriptionManager.ProductID(rawValue: "com.phonecare.premium.weekly") == .weekly)
        #expect(SubscriptionManager.ProductID(rawValue: "com.phonecare.premium.monthly") == .monthly)
    }

    @Test("ProductID returns nil for an unknown raw value")
    func productID_unknownRawValue() {
        #expect(SubscriptionManager.ProductID(rawValue: "com.competitor.app") == nil)
    }

    // MARK: - Initial state

    @Test("Manager starts with no products loaded")
    func initialState_noProducts() {
        let manager = SubscriptionManager()
        #expect(manager.products.isEmpty)
    }

    @Test("Manager starts not loading")
    func initialState_notLoading() {
        let manager = SubscriptionManager()
        #expect(manager.isLoading == false)
    }

    @Test("Manager starts with no purchase error")
    func initialState_noPurchaseError() {
        let manager = SubscriptionManager()
        #expect(manager.purchaseError == nil)
    }

    @Test("Manager starts with no expiration date")
    func initialState_noExpirationDate() {
        let manager = SubscriptionManager()
        #expect(manager.expirationDate == nil)
    }

    @Test("Manager starts not in grace period")
    func initialState_notInGracePeriod() {
        let manager = SubscriptionManager()
        #expect(manager.isInGracePeriod == false)
    }

    // MARK: - UserDefaults premium caching

    @Test("Manager reads cached premium state as true when UserDefaults key is set")
    func init_readsCachedPremiumTrue() {
        let key = "PhoneCare_isPremium"
        UserDefaults.standard.set(true, forKey: key)
        defer { UserDefaults.standard.removeObject(forKey: key) }

        let manager = SubscriptionManager()
        #expect(manager.isPremium == true)
    }

    @Test("Manager reads cached premium state as false when UserDefaults key is absent")
    func init_readsCachedPremiumFalse() {
        let key = "PhoneCare_isPremium"
        UserDefaults.standard.removeObject(forKey: key)

        let manager = SubscriptionManager()
        #expect(manager.isPremium == false)
    }

    @Test("Trial and currentProductID are nil before any entitlement check")
    func initialState_noTrialOrProduct() {
        let manager = SubscriptionManager()
        #expect(manager.isInTrial == false)
        #expect(manager.currentProductID == nil)
    }
}
