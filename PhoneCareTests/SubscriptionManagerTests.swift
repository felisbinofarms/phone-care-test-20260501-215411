import Testing
import Foundation
@testable import PhoneCare

@Suite("SubscriptionManager")
@MainActor
struct SubscriptionManagerTests {

    // MARK: - ProductID enum

    @Test("Every ProductID case round-trips through init(rawValue:)")
    func productID_roundTrip() {
        for id in SubscriptionManager.ProductID.allCases {
            #expect(SubscriptionManager.ProductID(rawValue: id.rawValue) == id,
                    "\(id) did not round-trip through rawValue")
        }
    }

    @Test("Every ProductID has a non-empty raw value starting with the app bundle prefix")
    func productID_rawValueFormat() {
        for id in SubscriptionManager.ProductID.allCases {
            #expect(!id.rawValue.isEmpty)
            #expect(id.rawValue.hasPrefix("com.phonecare.premium."),
                    "\(id.rawValue) missing expected bundle prefix")
        }
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

    // MARK: - Premium state consistency

    @Test("Two managers created in the same process agree on isPremium")
    func isPremium_consistentAcrossInstances() {
        let a = SubscriptionManager()
        let b = SubscriptionManager()
        #expect(a.isPremium == b.isPremium)
    }

    @Test("Trial and currentProductID are nil before any entitlement check")
    func initialState_noTrialOrProduct() {
        let manager = SubscriptionManager()
        #expect(manager.isInTrial == false)
        #expect(manager.currentProductID == nil)
    }
}
