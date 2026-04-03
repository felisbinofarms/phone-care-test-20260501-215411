import SwiftUI
import SwiftData

struct DuplicateContactGroup: Identifiable {
    let id: String
    let name: String
    let suggestedPrimaryID: String
    let contactIDs: [String]
    let fields: [ContactField]
}

struct ContactField: Identifiable {
    let id: String
    let label: String
    let values: [String] // One per contact in the group
    var selectedIndex: Int // Which contact's value to keep
}

@MainActor
@Observable
final class ContactsViewModel {

    // MARK: - State

    private(set) var duplicateGroups: [DuplicateContactGroup] = []
    private(set) var isLoading: Bool = false
    private(set) var isScanning: Bool = false
    private(set) var scanComplete: Bool = false
    private(set) var totalContacts: Int = 0
    private(set) var duplicateCount: Int = 0

    var showUndoToast: Bool = false
    private(set) var lastMergedCount: Int = 0

    private let analyzer = ContactAnalyzer()
    private let undoManager = CleanupUndoManager()
    private var lastUndoActionID: UUID?
    private var lastUndoContext: (primaryID: String, mergeDate: Date)?

    // MARK: - Load

    func load(dataManager: DataManager) {
        isLoading = true
        defer { isLoading = false }

        do {
            if let scan = try dataManager.latestScanResult() {
                totalContacts = scan.contactCount
                duplicateCount = scan.duplicateContactCount
                scanComplete = duplicateCount > 0 || totalContacts > 0
            }
        } catch {
            // Show empty state
        }
    }

    // MARK: - Scan

    func startScan(dataManager: DataManager) {
        isScanning = true
        Task {
            let result = await analyzer.analyze()
            totalContacts = result.totalContacts
            duplicateCount = result.duplicateCount
            duplicateGroups = result.duplicateGroups.map(Self.makeGroup)
            await saveContactCounts(result: result, dataManager: dataManager)
            isScanning = false
            scanComplete = true
        }
    }

    // MARK: - Merge

    func mergeGroup(_ group: DuplicateContactGroup, dataManager: DataManager) {
        guard group.contactIDs.count > 1 else { return }

        Task {
            let removeIDs = group.contactIDs.filter { $0 != group.suggestedPrimaryID }
            let mergeDate = Date()
            do {
                try await analyzer.mergeContacts(
                    keepIdentifier: group.suggestedPrimaryID,
                    removeIdentifiers: removeIDs,
                    dataManager: dataManager
                )

                let actionID = UUID()
                lastUndoActionID = actionID
                lastUndoContext = (primaryID: group.suggestedPrimaryID, mergeDate: mergeDate)

                undoManager.registerAction(
                    id: actionID,
                    actionType: .contactMerge,
                    itemCount: removeIDs.count
                ) {
                    try await self.analyzer.restoreMergedContacts(
                        mergedInto: group.suggestedPrimaryID,
                        mergedAfter: mergeDate,
                        dataManager: dataManager
                    )
                }

                duplicateGroups.removeAll { $0.id == group.id }
                duplicateCount = max(0, duplicateCount - removeIDs.count)
                lastMergedCount = removeIDs.count
                showUndoToast = true
            } catch {
                // Keep UI stable on merge failure.
            }
        }
    }

    func mergeAll(dataManager: DataManager) {
        let groups = duplicateGroups
        for group in groups {
            mergeGroup(group, dataManager: dataManager)
        }
    }

    func undoMerge(dataManager: DataManager) {
        guard let actionID = lastUndoActionID else {
            showUndoToast = false
            return
        }

        Task {
            _ = try? await undoManager.undo(id: actionID)
            showUndoToast = false
            startScan(dataManager: dataManager)
        }
    }

    // MARK: - Helpers

    private static func makeGroup(from analyzerGroup: ContactDuplicateGroup) -> DuplicateContactGroup {
        let displayName = analyzerGroup.contactNames.first(where: { $0 != "No name" }) ?? "Unnamed contact"
        return DuplicateContactGroup(
            id: analyzerGroup.id,
            name: displayName,
            suggestedPrimaryID: analyzerGroup.suggestedPrimaryIdentifier,
            contactIDs: analyzerGroup.contactIdentifiers,
            fields: [
                ContactField(
                    id: "name_\(analyzerGroup.id)",
                    label: "Name",
                    values: analyzerGroup.contactNames,
                    selectedIndex: max(0, analyzerGroup.contactIdentifiers.firstIndex(of: analyzerGroup.suggestedPrimaryIdentifier) ?? 0)
                ),
                ContactField(
                    id: "reason_\(analyzerGroup.id)",
                    label: "Why these were grouped",
                    values: Array(repeating: analyzerGroup.matchReason.rawValue, count: analyzerGroup.contactIdentifiers.count),
                    selectedIndex: 0
                ),
            ]
        )
    }

    private func saveContactCounts(result: ContactAnalysisResult, dataManager: DataManager) async {
        do {
            if let latest = try dataManager.latestScanResult() {
                latest.contactCount = result.totalContacts
                latest.duplicateContactCount = result.duplicateCount
                try dataManager.saveContext()
            } else {
                let scan = ScanResult(
                    contactCount: result.totalContacts,
                    duplicateContactCount: result.duplicateCount
                )
                try dataManager.save(scan)
            }
        } catch {
            // Keep scan UX responsive even if persistence fails.
        }
    }
}
