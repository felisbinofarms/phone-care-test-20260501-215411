import Foundation
import OSLog

// MARK: - Undo Action

struct UndoAction: Identifiable, Sendable {
    let id: UUID
    let actionType: CleanupActionType
    let itemCount: Int
    let deadline: Date
    let registeredAt: Date

    var remainingSeconds: TimeInterval {
        max(0, deadline.timeIntervalSinceNow)
    }

    var isExpired: Bool {
        Date() > deadline
    }
}

// MARK: - Manager

@MainActor
@Observable
final class CleanupUndoManager {

    // MARK: - Durations

    static let photoDeletionUndoDuration: TimeInterval = 30          // 30 seconds
    static let contactMergeUndoDuration: TimeInterval = 30 * 24 * 3600  // 30 days
    static let videoCompressUndoDuration: TimeInterval = 30          // 30 seconds

    // MARK: - State

    /// Currently active (non-expired) undo actions, published for UI.
    private(set) var activeUndoActions: [UndoAction] = []

    // MARK: - Private

    private var undoHandlers: [UUID: () async throws -> Void] = [:]
    private var expirationTimers: [UUID: Task<Void, Never>] = [:]
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "PhoneCare", category: "CleanupUndoManager")

    // MARK: - Register

    /// Registers a cleanup action that can be undone within `duration` seconds.
    func registerAction(
        id: UUID,
        actionType: CleanupActionType,
        itemCount: Int,
        duration: TimeInterval? = nil,
        undoHandler: @escaping () async throws -> Void
    ) {
        let effectiveDuration = duration ?? defaultDuration(for: actionType)
        let deadline = Date().addingTimeInterval(effectiveDuration)

        let action = UndoAction(
            id: id,
            actionType: actionType,
            itemCount: itemCount,
            deadline: deadline,
            registeredAt: Date()
        )

        undoHandlers[id] = undoHandler
        activeUndoActions.append(action)

        // Schedule automatic expiration.
        let timerId = id
        expirationTimers[timerId]?.cancel()
        expirationTimers[timerId] = Task { [weak self] in
            try? await Task.sleep(for: .seconds(effectiveDuration))
            guard !Task.isCancelled else { return }
            self?.expire(id: id)
        }

        logger.info("Registered undo action \(id) with \(effectiveDuration)s window.")
    }

    // MARK: - Undo

    /// Executes the undo handler if the action is still within its window.
    /// Returns `true` on success.
    @discardableResult
    func undo(id: UUID) async throws -> Bool {
        guard let handler = undoHandlers[id] else {
            logger.warning("No undo handler found for \(id).")
            return false
        }

        guard isUndoAvailable(id: id) else {
            logger.warning("Undo window expired for \(id).")
            return false
        }

        try await handler()
        cleanup(id: id)
        logger.info("Undo executed for \(id).")
        return true
    }

    // MARK: - Query

    func isUndoAvailable(id: UUID) -> Bool {
        guard let action = activeUndoActions.first(where: { $0.id == id }) else {
            return false
        }
        return !action.isExpired
    }

    func undoAction(for id: UUID) -> UndoAction? {
        activeUndoActions.first(where: { $0.id == id })
    }

    // MARK: - Cancel

    /// Cancel an undo registration without executing the handler.
    func cancelUndo(id: UUID) {
        cleanup(id: id)
        logger.info("Undo cancelled for \(id).")
    }

    /// Remove all undo actions.
    func clearAll() {
        let ids = activeUndoActions.map(\.id)
        for id in ids {
            cleanup(id: id)
        }
    }

    // MARK: - Private

    private func expire(id: UUID) {
        cleanup(id: id)
        logger.debug("Undo expired for \(id).")
    }

    private func cleanup(id: UUID) {
        undoHandlers.removeValue(forKey: id)
        expirationTimers[id]?.cancel()
        expirationTimers.removeValue(forKey: id)
        activeUndoActions.removeAll { $0.id == id }
    }

    private func defaultDuration(for type: CleanupActionType) -> TimeInterval {
        switch type {
        case .photoDelete:   return Self.photoDeletionUndoDuration
        case .contactMerge:  return Self.contactMergeUndoDuration
        case .videoCompress: return Self.videoCompressUndoDuration
        }
    }
}
