import Foundation

enum SharePromptType {
    case photoDelete(bytesFreed: Int64)
    case contactMerge(count: Int)
    case guidedFlow(flowType: GuidedFlowType, itemsCleaned: Int, bytesFreed: Int64)
    case privacyAudit
}

@MainActor
@Observable
final class SharePromptManager {

    private static let cooldownInterval: TimeInterval = 7 * 24 * 60 * 60 // 7 days

    private static var shareLinkSuffix: String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "PhoneCareAppStoreURL") as? String,
              let url = URL(string: value),
              !url.absoluteString.isEmpty else {
            return ""
        }

        return " \(url.absoluteString)"
    }

    private static func appendShareLink(to message: String) -> String {
        guard !shareLinkSuffix.isEmpty else {
            return message
        }

        return "\(message)\(shareLinkSuffix)"
    }

    func shouldShowPrompt(dataManager: DataManager) -> Bool {
        guard let prefs = try? dataManager.fetch(
            UserPreferences.self,
            fetchLimit: 1
        ).first else {
            return true
        }
        guard let lastShown = prefs.sharePromptLastShownAt else {
            return true
        }
        return Date().timeIntervalSince(lastShown) >= Self.cooldownInterval
    }

    func recordPromptShown(dataManager: DataManager) {
        do {
            if let prefs = try dataManager.fetch(UserPreferences.self, fetchLimit: 1).first {
                prefs.sharePromptLastShownAt = Date()
                try dataManager.saveContext()
            } else {
                let newPrefs = UserPreferences(sharePromptLastShownAt: Date())
                try dataManager.save(newPrefs)
            }
        } catch {
            // Non-critical — prompt may show again sooner
        }
    }

    static func shareMessage(for type: SharePromptType) -> String {
        switch type {
        case .photoDelete(let bytesFreed):
            let formatted = ByteCountFormatter.string(fromByteCount: bytesFreed, countStyle: .file)
            return appendShareLink(to: "I just freed up \(formatted) of space on my iPhone with PhoneCare! If your phone is always full, check it out.")
        case .contactMerge(let count):
            return appendShareLink(to: "I just merged \(count) duplicate contacts with PhoneCare. My phone is so much more organized!")
        case .guidedFlow(_, let itemsCleaned, let bytesFreed):
            if bytesFreed > 0 {
                let formatted = ByteCountFormatter.string(fromByteCount: bytesFreed, countStyle: .file)
                return appendShareLink(to: "I just cleaned up my iPhone with PhoneCare — \(itemsCleaned) items cleaned, \(formatted) freed! Try it.")
            }
            return appendShareLink(to: "I just cleaned up my iPhone with PhoneCare — \(itemsCleaned) items tidied up! Try it.")
        case .privacyAudit:
            return appendShareLink(to: "I just reviewed all my iPhone privacy settings with PhoneCare. Turns out I'm in great shape!")
        }
    }

    static func promptMessage(for type: SharePromptType) -> String {
        switch type {
        case .photoDelete(let bytesFreed):
            let formatted = ByteCountFormatter.string(fromByteCount: bytesFreed, countStyle: .file)
            return "You freed up \(formatted)! Know someone whose phone is always full?"
        case .contactMerge(let count):
            return "You merged \(count) duplicate contacts. Your phone is more organized than ever!"
        case .guidedFlow:
            return "Nice cleanup! Know someone who could use a hand with their phone?"
        case .privacyAudit:
            return "You're in good shape. Know someone worried about phone privacy?"
        }
    }
}
