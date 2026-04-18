import SwiftUI
import SwiftData

@main
struct PhoneCareApp: App {
    @State private var appState = AppState()
    @State private var subscriptionManager = SubscriptionManager()
    @State private var permissionManager = PermissionManager()
    @State private var dataManager = DataManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(subscriptionManager)
                .environment(permissionManager)
                .environment(dataManager)
                .modelContainer(dataManager.modelContainer)
                .preferredColorScheme(appState.resolvedColorScheme)
                .task {
                    guard !LaunchArguments.contains(LaunchArguments.skipStoreKitForUITests) else { return }
                    subscriptionManager.startTransactionListener()
                    await subscriptionManager.loadProducts()
                    await subscriptionManager.checkEntitlement()
                }
                .task {
                    dataManager.enforceRetention()
                }
        }
    }
}
