import Foundation

// MARK: - Domain Scores

struct DomainScore: Sendable {
    let domain: String
    let score: Int
    let weight: Double
    let weightedScore: Double
}

struct HealthScoreResult: Sendable {
    let compositeScore: Int
    let breakdown: [DomainScore]

    var storageScore: Int { score(for: "storage") }
    var photoScore: Int { score(for: "photos") }
    var contactScore: Int { score(for: "contacts") }
    var batteryScore: Int { score(for: "battery") }
    var privacyScore: Int { score(for: "privacy") }

    private func score(for domain: String) -> Int {
        breakdown.first(where: { $0.domain == domain })?.score ?? 0
    }
}

// MARK: - Input

struct HealthScoreInput: Sendable {
    // Storage
    let totalStorageBytes: Int64
    let usedStorageBytes: Int64

    // Photos
    let totalPhotos: Int
    let duplicatePhotos: Int

    // Contacts
    let totalContacts: Int
    let duplicateContacts: Int

    // Battery
    let batteryHealth: Double?   // 0-1, nil if unavailable
    let batteryLevel: Double     // 0-1

    // Privacy
    let totalPermissions: Int
    let appropriatelySetPermissions: Int
}

// MARK: - Calculator

final class HealthScoreCalculator {

    // MARK: - Thresholds

    static let goodThreshold: Int = 51

    // MARK: - Weights

    private static let storageWeight:  Double = 0.40
    private static let photoWeight:    Double = 0.20
    private static let contactWeight:  Double = 0.10
    private static let batteryWeight:  Double = 0.20
    private static let privacyWeight:  Double = 0.10

    // MARK: - Calculate

    static func calculate(from input: HealthScoreInput) -> HealthScoreResult {
        let storage  = storageScore(total: input.totalStorageBytes, used: input.usedStorageBytes)
        let photos   = photoScore(total: input.totalPhotos, duplicates: input.duplicatePhotos)
        let contacts = contactScore(total: input.totalContacts, duplicates: input.duplicateContacts)
        let battery  = batteryScore(health: input.batteryHealth, level: input.batteryLevel)
        let privacy  = privacyScore(total: input.totalPermissions, appropriate: input.appropriatelySetPermissions)

        let domains: [(String, Int, Double)] = [
            ("storage",  storage,  storageWeight),
            ("photos",   photos,   photoWeight),
            ("contacts", contacts, contactWeight),
            ("battery",  battery,  batteryWeight),
            ("privacy",  privacy,  privacyWeight),
        ]

        let breakdown = domains.map { name, score, weight in
            DomainScore(
                domain: name,
                score: score,
                weight: weight,
                weightedScore: Double(score) * weight
            )
        }

        let composite = breakdown.reduce(0.0) { $0 + $1.weightedScore }
        let clamped = max(0, min(100, Int(composite.rounded())))

        return HealthScoreResult(compositeScore: clamped, breakdown: breakdown)
    }

    // MARK: - Sub-Scores

    /// 100 if >= 50 % free. Linearly decreases to 0 when 0 % free.
    static func storageScore(total: Int64, used: Int64) -> Int {
        guard total > 0 else { return 100 }
        let freePercent = Double(total - used) / Double(total) * 100.0

        if freePercent >= 50 {
            return 100
        }
        // Linear scale: 0 % free -> 0, 50 % free -> 100.
        let score = (freePercent / 50.0) * 100.0
        return clamp(Int(score.rounded()))
    }

    /// 100 minus a penalty based on the ratio of duplicates to total photos.
    /// Penalty: (duplicates / total) * 100, so 50% duplicates = score 50.
    static func photoScore(total: Int, duplicates: Int) -> Int {
        guard total > 0, duplicates > 0 else { return 100 }
        let ratio = Double(min(duplicates, total)) / Double(total)
        let penalty = ratio * 100.0
        return clamp(Int((100.0 - penalty).rounded()))
    }

    /// 100 minus a penalty based on the ratio of duplicate contacts.
    static func contactScore(total: Int, duplicates: Int) -> Int {
        guard total > 0, duplicates > 0 else { return 100 }
        let ratio = Double(min(duplicates, total)) / Double(total)
        let penalty = ratio * 100.0
        return clamp(Int((100.0 - penalty).rounded()))
    }

    /// Based on battery health percentage. Falls back to battery level if health is unavailable.
    static func batteryScore(health: Double?, level: Double) -> Int {
        let value = health ?? level
        let percentage = value * 100.0
        return clamp(Int(percentage.rounded()))
    }

    /// Percentage of permissions that are appropriately configured.
    static func privacyScore(total: Int, appropriate: Int) -> Int {
        guard total > 0 else { return 100 }
        let ratio = Double(min(appropriate, total)) / Double(total) * 100.0
        return clamp(Int(ratio.rounded()))
    }

    // MARK: - Helpers

    private static func clamp(_ value: Int) -> Int {
        max(0, min(100, value))
    }
}
