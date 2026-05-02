---
name: health-score-calculation
user-invocable: true
description: "Use when: calculating composite health score, weighting battery/storage/permissions, displaying score with correct colors (green/amber never red), testing score edge cases, tuning scoring algorithm."
---

# PhoneCare Health Score Calculation Skill

Algorithm for calculating composite phone health score with anti-scareware color compliance.

## Health Score Formula

```
HealthScore = (Battery × 0.30) + (Storage × 0.40) + (Permissions × 0.30)
```

**Weights Rationale:**
- Battery (30%): Most visible impact, battery health important
- Storage (40%): Highest user concern, directly actionable
- Permissions (30%): Privacy/security important, less urgent

## Component Scores (0–100)

### Battery Health (0–100)

```swift
func calculateBatteryScore(level: Int, state: UIDevice.BatteryState) -> Int {
    var score = level  // Start with charge level
    
    // Penalty for critical states
    switch state {
    case .unplugged:
        if level < 20 { score -= 10 }  // Low battery penalty
    case .charging:
        score += 5  // Small boost for charging
    default:
        break
    }
    
    return max(0, min(100, score))
}

// Examples:
// - 100% charging → 95 (excellent)
// - 80% unplugged → 80 (good)
// - 15% unplugged → 5 (critical)
// - 0% → 0 (dead)
```

### Storage Health (0–100)

```swift
func calculateStorageScore(totalStorage: Int64, availableStorage: Int64) -> Int {
    let percentFree = Double(availableStorage) / Double(totalStorage) * 100
    
    // Score based on free space percentage
    switch percentFree {
    case 50...: return 100  // >50% free: Excellent
    case 30..<50: return 80  // 30–50% free: Good
    case 15..<30: return 50  // 15–30% free: Warning
    case 10..<15: return 30  // 10–15% free: Critical
    default: return 0  // <10% free: Emergency
    }
}

// Examples:
// - 256GB total, 150GB free (58%) → 100 (excellent)
// - 256GB total, 100GB free (39%) → 80 (good)
// - 256GB total, 40GB free (15%) → 50 (warning)
// - 256GB total, 20GB free (7%) → 0 (emergency)
```

### Permissions Health (0–100)

```swift
func calculatePermissionsScore(permissions: [PermissionStatus]) -> Int {
    let critical = ["Photos", "Contacts", "Location", "Microphone", "Camera"]
    
    var score = 100
    
    for permission in permissions {
        if critical.contains(permission.name) && permission.granted {
            score -= 10  // -10 for each critical permission granted
        }
    }
    
    return max(0, min(100, score))
}

// Examples:
// - No permissions → 100 (private)
// - Photos, Contacts, Location → 70 (some access)
// - All 5 critical permissions → 50 (exposed)
```

## Composite Score Calculation

```swift
@Observable
final class HealthScoreCalculator {
    private let batteryMonitor: BatteryMonitor
    private let storageAnalyzer: StorageAnalyzer
    private let permissionManager: PermissionManager
    
    func calculateHealthScore() async -> Int {
        let batteryScore = await batteryMonitor.getHealthScore()
        let storageScore = await storageAnalyzer.getHealthScore()
        let permissionsScore = await permissionManager.getHealthScore()
        
        // Weighted composite
        let composite = Int(
            Double(batteryScore) * 0.30 +
            Double(storageScore) * 0.40 +
            Double(permissionsScore) * 0.30
        )
        
        return max(0, min(100, composite))
    }
}
```

## Score Color Mapping (ANTI-SCAREWARE)

**CRITICAL: NEVER use red for health scores**

```swift
enum ScoreColor {
    case green      // 51–100 (Healthy)
    case amber      // 0–50 (Needs attention)
    
    static func color(for score: Int) -> ScoreColor {
        switch score {
        case 51...100: return .green   // ✓ Good
        case 0...50: return .amber     // ⚠️ Warning
        default: return .amber         // Safe default
        }
    }
}

// SwiftUI Usage:
@MainActor
func scoreColor(for score: Int) -> Color {
    switch score {
    case 51...100: return Color.accent  // Green (#1A8A6E)
    case 0...50: return Color.warning   // Amber (#F39C12)
    default: return Color.warning
    }
}

// NEVER:
// return Color.red  // ❌ BLOCKED
// return Color.orange  // ❌ BLOCKED
```

## Score Display Examples

```swift
struct HealthScoreView: View {
    let score: Int
    
    var scoreColor: Color {
        score >= 51 ? Color.accent : Color.warning
    }
    
    var scoreText: String {
        switch score {
        case 80...100: return "Great health"
        case 60..<80: return "Good health"
        case 40..<60: return "Fair health"
        default: return "Needs attention"
        }
    }
    
    var body: some View {
        VStack(spacing: .sm) {
            // Circle with score
            ZStack {
                Circle()
                    .fill(scoreColor.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                VStack(spacing: .xs) {
                    Text("\(score)%")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(scoreColor)
                    
                    Text("Health")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            
            // Descriptive text (calm, not scary)
            Text(scoreText)
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            // Actionable suggestion
            Group {
                if score < 50 {
                    Text("Free up storage to improve health")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }
}
```

## Edge Cases

| Case | Score | Reason |
|------|-------|--------|
| Device just powered on | ~60–80 | Battery high, fresh state |
| Phone near empty | 0–10 | <10% storage free, critical |
| Battery critically low + full storage | 5–15 | Bad battery + no space |
| Perfect health | 95–100 | Battery charged, space free, private |
| All permissions granted | ~60 | Good storage/battery but exposed |
| Restored from backup | ~70 | Variable, depends on device state |

## Testing Strategy

```swift
func testHealthScoreCalculation() {
    let calc = HealthScoreCalculator(battery: 80, storage: 50, permissions: 100)
    let score = calc.calculate()
    
    // Score = (80 * 0.30) + (50 * 0.40) + (100 * 0.30)
    //       = 24 + 20 + 30 = 74
    XCTAssertEqual(score, 74)
}

func testScoreBoundary0() {
    let score = HealthScoreCalculator(battery: 0, storage: 0, permissions: 0).calculate()
    XCTAssertEqual(score, 0)
}

func testScoreBoundary100() {
    let score = HealthScoreCalculator(battery: 100, storage: 100, permissions: 100).calculate()
    XCTAssertEqual(score, 100)
}

func testScoreColor_Green() {
    let score = 75
    let color = scoreColor(for: score)
    XCTAssertEqual(color, Color.accent)  // Green
}

func testScoreColor_Amber() {
    let score = 25
    let color = scoreColor(for: score)
    XCTAssertEqual(color, Color.warning)  // Amber
}
```

## Dashboard Display

```swift
struct DashboardView: View {
    @State var healthScore = 65
    @State var loadingState = LoadingState.success
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .lg) {
                // Health Score Card (PRIMARY)
                Card {
                    HealthScoreView(score: healthScore)
                }
                .padding(.horizontal, .lg)
                
                // Drill-down Cards (SECONDARY)
                Card {
                    HStack {
                        VStack(alignment: .leading, spacing: .xs) {
                            Text("Battery Health")
                                .font(.body)
                                .foregroundColor(.textPrimary)
                            Text("75%")
                                .font(.headline)
                                .foregroundColor(Color.accent)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.textSecondary)
                    }
                    .onTapGesture {
                        // Navigate to battery detail
                    }
                }
                .padding(.horizontal, .lg)
                
                // ... More cards for Storage, Permissions
            }
        }
    }
}
```

## Score Refresh Strategy

```swift
@MainActor
func refreshHealthScore() async {
    do {
        let newScore = try await calculateHealthScore()
        self.healthScore = newScore
        
        // Cache score + timestamp
        UserDefaults.standard.set(newScore, forKey: "healthScore")
        UserDefaults.standard.set(Date(), forKey: "healthScoreUpdatedAt")
    } catch {
        print("Failed to calculate health score: \(error)")
    }
}

// Call on app launch + periodically
.onAppear {
    Task { await refreshHealthScore() }
}
```

## Anti-Scareware Checklist

- [ ] Health score never shows RED
- [ ] Amber (warning) only for 0–50% scores
- [ ] Green for 51–100%
- [ ] No "CRITICAL" or "URGENT" language
- [ ] No fake threat alerts
- [ ] No countdown timers
- [ ] Score text is calm ("Needs attention", not "AT RISK!")
- [ ] All colors from Theme.swift (green/amber only)

---

**Use This Skill When:**
- Implementing health score calculation
- Adjusting weights or thresholds
- Validating anti-scareware color compliance
- Testing edge cases
- Tuning algorithm based on QA feedback
