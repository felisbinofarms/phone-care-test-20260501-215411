import Foundation
import SwiftData
import OSLog

@Observable
final class DataManager {

    // MARK: - Properties

    let modelContainer: ModelContainer

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "PhoneCare", category: "DataManager")

    // MARK: - Schema

    static let allModels: [any PersistentModel.Type] = [
        UserPreferences.self,
        ScanResult.self,
        ScanDetail.self,
        CleanupAction.self,
        BatterySnapshot.self,
        ContactBackup.self,
        PhotoScanCache.self
    ]

    // MARK: - Init

    init(inMemory: Bool = false) {
        let schema = Schema(Self.allModels)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // On-disk store failed (e.g., schema migration conflict, disk full).
            // Fall back to an in-memory container so the app can still launch.
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                modelContainer = try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                fatalError("Failed to create even an in-memory ModelContainer: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Context Helpers

    @MainActor
    var mainContext: ModelContext {
        modelContainer.mainContext
    }

    func newBackgroundContext() -> ModelContext {
        ModelContext(modelContainer)
    }

    // MARK: - Generic Fetch

    @MainActor
    func fetch<T: PersistentModel>(
        _ type: T.Type,
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = [],
        fetchLimit: Int? = nil
    ) throws -> [T] {
        var descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
        descriptor.fetchLimit = fetchLimit
        return try mainContext.fetch(descriptor)
    }

    // MARK: - Generic Save

    @MainActor
    func save<T: PersistentModel>(_ model: T) throws {
        mainContext.insert(model)
        try mainContext.save()
    }

    @MainActor
    func saveContext() throws {
        if mainContext.hasChanges {
            try mainContext.save()
        }
    }

    // MARK: - Generic Delete

    @MainActor
    func delete<T: PersistentModel>(_ model: T) throws {
        mainContext.delete(model)
        try mainContext.save()
    }

    @MainActor
    func deleteAll<T: PersistentModel>(_ type: T.Type) throws {
        try mainContext.delete(model: type)
        try mainContext.save()
    }

    // MARK: - User Preferences (Singleton)

    @MainActor
    func userPreferences() throws -> UserPreferences {
        let existing = try fetch(UserPreferences.self, fetchLimit: 1)
        if let prefs = existing.first {
            return prefs
        }
        let prefs = UserPreferences()
        try save(prefs)
        return prefs
    }

    // MARK: - Latest Scan

    @MainActor
    func latestScanResult() throws -> ScanResult? {
        try fetch(
            ScanResult.self,
            sortBy: [SortDescriptor(\.scanDate, order: .reverse)],
            fetchLimit: 1
        ).first
    }

    // MARK: - Retention Enforcement

    @MainActor
    func enforceRetention() {
        do {
            try pruneOldScanResults(keepCount: 30)
            try pruneOldBatterySnapshots(retentionDays: BatterySnapshot.retentionDays)
            try pruneExpiredContactBackups(retentionDays: ContactBackup.retentionDays)
            try pruneExpiredUndoData()
            try saveContext()
            logger.info("Retention enforcement completed.")
        } catch {
            logger.error("Retention enforcement failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete All Data

    @MainActor
    func deleteAllData() throws {
        try deleteAll(ScanDetail.self)
        try deleteAll(ScanResult.self)
        try deleteAll(CleanupAction.self)
        try deleteAll(BatterySnapshot.self)
        try deleteAll(ContactBackup.self)
        try deleteAll(PhotoScanCache.self)
        try deleteAll(UserPreferences.self)
        logger.info("All data deleted.")
    }

    // MARK: - Private Retention Helpers

    @MainActor
    private func pruneOldScanResults(keepCount: Int) throws {
        let allResults = try fetch(
            ScanResult.self,
            sortBy: [SortDescriptor(\.scanDate, order: .reverse)]
        )
        guard allResults.count > keepCount else { return }

        let toDelete = allResults.dropFirst(keepCount)
        for result in toDelete {
            mainContext.delete(result)
        }
        logger.debug("Pruned \(toDelete.count) old scan results.")
    }

    @MainActor
    private func pruneOldBatterySnapshots(retentionDays: Int) throws {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) else { return }
        let old = try fetch(
            BatterySnapshot.self,
            predicate: #Predicate<BatterySnapshot> { $0.date < cutoff }
        )
        for snapshot in old {
            mainContext.delete(snapshot)
        }
        if !old.isEmpty {
            logger.debug("Pruned \(old.count) old battery snapshots.")
        }
    }

    @MainActor
    private func pruneExpiredContactBackups(retentionDays: Int) throws {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) else { return }
        let expired = try fetch(
            ContactBackup.self,
            predicate: #Predicate<ContactBackup> { $0.mergeDate < cutoff }
        )
        for backup in expired {
            mainContext.delete(backup)
        }
        if !expired.isEmpty {
            logger.debug("Pruned \(expired.count) expired contact backups.")
        }
    }

    @MainActor
    private func pruneExpiredUndoData() throws {
        let now = Date()
        let expired = try fetch(
            CleanupAction.self,
            predicate: #Predicate<CleanupAction> { $0.undoDeadline < now && $0.undoData != nil }
        )
        for action in expired {
            action.undoData = nil
        }
        if !expired.isEmpty {
            logger.debug("Cleared undo data from \(expired.count) expired cleanup actions.")
        }
    }
}
