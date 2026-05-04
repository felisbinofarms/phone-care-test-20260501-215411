import SwiftUI
import SwiftData
import Contacts

struct ContactsAlertInfo: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

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
    private(set) var isMerging: Bool = false
    var alertInfo: ContactsAlertInfo?
    var mergeError: String?

    private let analyzer = ContactAnalyzer()
    private let undoManager = CleanupUndoManager()
    private var lastUndoActionID: UUID?

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
        let authorization = CNContactStore.authorizationStatus(for: .contacts)
        guard authorization == .authorized else {
            duplicateGroups = []
            duplicateCount = 0
            totalContacts = 0
            scanComplete = false
            alertInfo = ContactsAlertInfo(
                title: "Contacts Access Needed",
                message: "Please allow Contacts access in Settings to scan for duplicates."
            )
            return
        }

        isScanning = true
        Task { @MainActor in
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
        guard !isMerging else { return }

        Task { @MainActor in
            mergeError = nil
            do {
                isMerging = true
                let token = try await performMerge(group, dataManager: dataManager)
                registerUndo(for: [token], dataManager: dataManager)

                duplicateGroups.removeAll { $0.id == group.id }
                duplicateCount = max(0, duplicateCount - token.mergedCount)
                lastMergedCount = token.mergedCount
                showUndoToast = true
            } catch {
                mergeError = error.localizedDescription
                alertInfo = ContactsAlertInfo(
                    title: "Merge Could Not Finish",
                    message: "We could not merge those contacts right now. Please try again."
                )
            }
            isMerging = false
        }
    }

    func mergeAll(dataManager: DataManager) {
        guard !isMerging else { return }
        let groups = duplicateGroups
        guard !groups.isEmpty else { return }

        Task { @MainActor in
            mergeError = nil
            isMerging = true
            var mergedTokens: [MergeUndoToken] = []
            var totalMerged = 0

            do {
                for group in groups {
                    let token = try await performMerge(group, dataManager: dataManager)
                    mergedTokens.append(token)
                    duplicateGroups.removeAll { $0.id == group.id }
                    totalMerged += token.mergedCount
                }

                duplicateCount = max(0, duplicateCount - totalMerged)
                lastMergedCount = totalMerged
                registerUndo(for: mergedTokens, dataManager: dataManager)
                showUndoToast = totalMerged > 0
            } catch {
                mergeError = error.localizedDescription
                alertInfo = ContactsAlertInfo(
                    title: "Merge Could Not Finish",
                    message: "Some contacts could not be merged. Nothing else was changed after the error."
                )
            }

            isMerging = false
        }
    }

    func undoMerge(dataManager: DataManager) {
        guard let actionID = lastUndoActionID else {
            showUndoToast = false
            return
        }

        Task { @MainActor in
            do {
                _ = try await undoManager.undo(id: actionID)
            } catch {
                alertInfo = ContactsAlertInfo(
                    title: "Undo Could Not Finish",
                    message: "We could not restore those contacts right now."
                )
            }
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
            alertInfo = ContactsAlertInfo(
                title: "Results Saved Partially",
                message: "Scan completed, but we could not save counts for later screens."
            )
        }
    }

    private struct MergeUndoToken {
        let primaryID: String
        let mergeDate: Date
        let mergedCount: Int
    }

    private func performMerge(_ group: DuplicateContactGroup, dataManager: DataManager) async throws -> MergeUndoToken {
        let removeIDs = group.contactIDs.filter { $0 != group.suggestedPrimaryID }
        guard !removeIDs.isEmpty else {
            throw ContactMergeError.mergeFailed("No duplicate contacts to remove from this group.")
        }
        let mergeDate = Date()

        try await analyzer.mergeContacts(
            keepIdentifier: group.suggestedPrimaryID,
            removeIdentifiers: removeIDs,
            dataManager: dataManager
        )

        return MergeUndoToken(
            primaryID: group.suggestedPrimaryID,
            mergeDate: mergeDate,
            mergedCount: removeIDs.count
        )
    }

    private func registerUndo(for tokens: [MergeUndoToken], dataManager: DataManager) {
        guard !tokens.isEmpty else { return }

        let actionID = UUID()
        lastUndoActionID = actionID

        undoManager.registerAction(
            id: actionID,
            actionType: .contactMerge,
            itemCount: tokens.reduce(0) { $0 + $1.mergedCount }
        ) {
            for token in tokens {
                try await self.analyzer.restoreMergedContacts(
                    mergedInto: token.primaryID,
                    mergedAfter: token.mergeDate,
                    dataManager: dataManager
                )
            }
        }
    }
}
