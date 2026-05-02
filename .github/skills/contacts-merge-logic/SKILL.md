---
name: contacts-merge-logic
user-invocable: true
description: "Use when: detecting duplicate contacts, fuzzy matching algorithms, merging contact data, conflict resolution, undo support, deduplication edge cases."
---

# PhoneCare Contact Merge Logic Skill

Duplicate contact detection, merge strategy, and conflict resolution.

## Duplicate Detection Algorithm

### Similarity Scoring

```swift
struct ContactMatch {
    let contact1: Contact
    let contact2: Contact
    let similarity: Double  // 0.0–1.0
}

class ContactAnalyzer {
    /// Detect if two contacts are likely duplicates
    func areDuplicates(_ c1: Contact, _ c2: Contact, threshold: Double = 0.75) -> Bool {
        let score = calculateSimilarity(c1, c2)
        return score >= threshold
    }
    
    /// Calculate overall similarity between two contacts
    func calculateSimilarity(_ c1: Contact, _ c2: Contact) -> Double {
        let nameMatch = nameDistance(c1.name, c2.name)
        let phoneMatch = phoneDistance(c1.phones, c2.phones)
        let emailMatch = emailDistance(c1.emails, c2.emails)
        
        // Weighted average
        let score = (nameMatch * 0.50) + (phoneMatch * 0.30) + (emailMatch * 0.20)
        return min(1.0, max(0.0, score))
    }
}
```

### Name Matching (Levenshtein Distance)

```swift
/// Calculate string similarity using Levenshtein distance
func levenshteinDistance(_ s1: String, _ s2: String) -> Double {
    let s1 = s1.lowercased()
    let s2 = s2.lowercased()
    
    let empty: [Int] = Array(repeating: 0, count: s2.count)
    var last = [Int](0...s2.count)
    
    for (i, char1) in s1.enumerated() {
        var cur = [i + 1] + empty
        for (j, char2) in s2.enumerated() {
            cur[j + 1] = char1 == char2 ? last[j] : 1 + min(last[j], last[j + 1], cur[j])
        }
        last = cur
    }
    
    // Convert distance to similarity (0.0–1.0)
    let maxLength = max(s1.count, s2.count)
    guard maxLength > 0 else { return 1.0 }
    
    return 1.0 - Double(last.last ?? 0) / Double(maxLength)
}

// Usage:
let similarity = levenshteinDistance("John Smith", "Jon Smith")  // 0.89 (likely match)
let similarity = levenshteinDistance("John", "Jane")  // 0.75 (possible match)
let similarity = levenshteinDistance("Alice", "Bob")  // 0.0 (not a match)
```

### Phone Number Matching

```swift
func phoneDistance(_ phones1: [String], _ phones2: [String]) -> Double {
    guard !phones1.isEmpty && !phones2.isEmpty else { return 0.0 }
    
    // Normalize phone numbers (remove non-digits)
    let normalize = { (phone: String) -> String in
        phone.filter { $0.isNumber }
    }
    
    let normalized1 = phones1.map(normalize)
    let normalized2 = phones2.map(normalize)
    
    // Find best match
    for p1 in normalized1 {
        for p2 in normalized2 {
            if p1 == p2 { return 1.0 }  // Exact match
            if p1.hasSuffix(p2) || p2.hasSuffix(p1) { return 0.9 }  // Partial match (last 7 digits)
        }
    }
    
    return 0.0  // No match
}

// Examples:
// phoneDistance(["415-555-1234"], ["415-555-1234"]) → 1.0 (exact)
// phoneDistance(["415-555-1234"], ["(415) 555-1234"]) → 1.0 (normalized)
// phoneDistance(["415-555-1234"], ["555-1234"]) → 0.9 (partial: last 7 digits)
// phoneDistance(["415-555-1234"], ["415-555-5678"]) → 0.0 (no match)
```

### Email Matching

```swift
func emailDistance(_ emails1: [String], _ emails2: [String]) -> Double {
    guard !emails1.isEmpty && !emails2.isEmpty else { return 0.0 }
    
    let normalized1 = emails1.map { $0.lowercased() }
    let normalized2 = emails2.map { $0.lowercased() }
    
    for e1 in normalized1 {
        for e2 in normalized2 {
            if e1 == e2 { return 1.0 }  // Exact match
            
            // Check if domain matches (suggests same person)
            let domain1 = e1.components(separatedBy: "@").last ?? ""
            let domain2 = e2.components(separatedBy: "@").last ?? ""
            if domain1 == domain2 && !domain1.isEmpty {
                return 0.7  // Same domain, weak link
            }
        }
    }
    
    return 0.0  // No match
}

// Examples:
// emailDistance(["john@example.com"], ["john@example.com"]) → 1.0
// emailDistance(["john@example.com"], ["jsmith@example.com"]) → 0.7
```

## Grouping Algorithm

```swift
/// Find all duplicate contact groups
func findDuplicateGroups(_ contacts: [Contact], threshold: Double = 0.75) -> [[Contact]] {
    var groups: [[Contact]] = []
    var processed = Set<String>()
    
    for contact in contacts {
        guard !processed.contains(contact.id) else { continue }
        
        var group = [contact]
        processed.insert(contact.id)
        
        // Find matches for this contact
        for other in contacts {
            guard !processed.contains(other.id) else { continue }
            
            let similarity = calculateSimilarity(contact, other)
            if similarity >= threshold {
                group.append(other)
                processed.insert(other.id)
            }
        }
        
        groups.append(group)
    }
    
    // Return only actual duplicates (>1 contact)
    return groups.filter { $0.count > 1 }
}
```

## Merge Strategy

### Field Conflict Resolution

```swift
enum MergeConflict {
    case phoneNumber(String, String)
    case email(String, String)
    case address(String, String)
    case note(String, String)
    
    var description: String {
        switch self {
        case .phoneNumber(let a, let b): return "Phone: \(a) vs \(b)"
        case .email(let a, let b): return "Email: \(a) vs \(b)"
        case .address(let a, let b): return "Address:\n\(a) vs \(b)"
        case .note(let a, let b): return "Note:\n\(a) vs \(b)"
        }
    }
}

func mergeContacts(_ primary: Contact, _ secondary: Contact) -> Contact {
    var merged = primary
    
    // Merge phone numbers (prefer primary, add secondary if new)
    var phones = Set(primary.phones)
    for phone in secondary.phones {
        phones.insert(phone)
    }
    merged.phones = Array(phones)
    
    // Merge emails (same strategy)
    var emails = Set(primary.emails)
    for email in secondary.emails {
        emails.insert(email)
    }
    merged.emails = Array(emails)
    
    // Use primary address, fall back to secondary
    if merged.address.isEmpty && !secondary.address.isEmpty {
        merged.address = secondary.address
    }
    
    // Append secondary notes if different
    if !secondary.note.isEmpty && !primary.note.isEmpty {
        merged.note = primary.note + "\n" + secondary.note
    } else if !secondary.note.isEmpty {
        merged.note = secondary.note
    }
    
    return merged
}
```

### User Confirmation Flow

```swift
struct MergeConfirmationView: View {
    let contact1: Contact
    let contact2: Contact
    let onConfirm: (Contact) -> Void
    
    @State var selectedConflictResolution: [String: String] = [:]
    
    var mergedContact: Contact {
        var merged = contact1
        for (key, choice) in selectedConflictResolution {
            // Apply user's conflict resolutions
        }
        return merged
    }
    
    var body: some View {
        VStack(spacing: .lg) {
            Text("Merge these contacts?")
                .font(.headline)
            
            // Show both contacts side-by-side
            HStack(spacing: .lg) {
                ContactPreview(contact: contact1)
                Image(systemName: "arrow.right")
                ContactPreview(contact: contact2)
            }
            
            // Show merged result
            VStack(alignment: .leading, spacing: .sm) {
                Text("Merged contact:")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                
                Card {
                    ContactPreview(contact: mergedContact)
                }
            }
            
            HStack(spacing: .md) {
                Button("Cancel") { dismiss() }
                Button("Merge") {
                    onConfirm(mergedContact)
                    dismiss()
                }
            }
        }
    }
}
```

## Undo Support

```swift
class ContactUndoManager {
    private struct Action {
        let timestamp: Date
        let originalContacts: [Contact]
        let deletedID: String
    }
    
    private var actions: [Action] = []
    private let undoWindow: TimeInterval = 24 * 60 * 60  // 24 hours
    
    func recordMerge(_ contact1: Contact, _ contact2: Contact) {
        actions.append(Action(
            timestamp: Date(),
            originalContacts: [contact1, contact2],
            deletedID: contact2.id
        ))
    }
    
    func canUndo() -> Bool {
        guard let lastAction = actions.last else { return false }
        let timeSince = Date().timeIntervalSince(lastAction.timestamp)
        return timeSince < undoWindow
    }
    
    func undo() -> [Contact]? {
        guard canUndo(), let action = actions.popLast() else { return nil }
        return action.originalContacts
    }
}
```

## Edge Cases

| Edge Case | Handling |
|-----------|----------|
| Contact with no name | Use first phone or email as identifier |
| Duplicate merge attempts | Check if already merged (prevent double merge) |
| Circular references | None (contacts are independent) |
| Merging with self | Check before merge: contact1.id != contact2.id |
| Contact deleted between merge | Gracefully fail with error message |
| Undo after 24 hours | Undo button disabled, merge permanent |
| Merge then immediately edit | New data saved, undo still works with original |

## Testing

```swift
func testDuplicateDetection() {
    let john1 = Contact(name: "John Smith", phone: "415-555-1234")
    let john2 = Contact(name: "Jon Smith", phone: "415-555-1234")
    
    let similarity = analyzer.calculateSimilarity(john1, john2)
    XCTAssertGreaterThan(similarity, 0.75)  // Above threshold
}

func testMergePhones() {
    let c1 = Contact(name: "John", phones: ["415-555-1234"])
    let c2 = Contact(name: "Jon", phones: ["415-555-5678"])
    
    let merged = ContactAnalyzer.mergeContacts(c1, c2)
    
    XCTAssertEqual(merged.phones.count, 2)
    XCTAssertTrue(merged.phones.contains("415-555-1234"))
    XCTAssertTrue(merged.phones.contains("415-555-5678"))
}

func testUndoMerge() {
    let manager = ContactUndoManager()
    let c1 = Contact(name: "John", id: "1")
    let c2 = Contact(name: "Jon", id: "2")
    
    manager.recordMerge(c1, c2)
    XCTAssertTrue(manager.canUndo())
    
    let restored = manager.undo()
    XCTAssertEqual(restored?.count, 2)
}
```

## Algorithm Threshold Tuning

**Similarity threshold trade-offs:**

| Threshold | False Positives | False Negatives | Use Case |
|-----------|-----------------|-----------------|----------|
| 0.60–0.70 | Many false matches | Few misses | Too aggressive |
| **0.75–0.80** | **Few false matches** | **Few misses** | **MVP (Recommended)** |
| 0.85–0.90 | Rare false matches | Some misses | Conservative |
| >0.95 | Almost no false matches | Many misses | Too strict |

**Recommendation: Start at 0.75, adjust based on QA feedback**

---

**Use This Skill When:**
- Implementing contact duplicate detection
- Designing merge conflict resolution
- Testing edge cases
- Tuning similarity threshold
- Implementing undo functionality
