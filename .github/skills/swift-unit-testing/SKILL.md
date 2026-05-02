---
name: swift-unit-testing
user-invocable: true
description: "Use when: writing unit tests, testing business logic, mocking dependencies, testing edge cases, calculating code coverage, test-driven development, refactoring with test safety."
---

# PhoneCare Swift Unit Testing Skill

Comprehensive unit testing framework for PhoneCare business logic.

## Test File Structure

```
PhoneCareTests/
├── HealthScoreCalculatorTests.swift
├── PhotoAnalyzerTests.swift
├── ContactAnalyzerTests.swift
├── SubscriptionManagerTests.swift
├── StorageAnalyzerTests.swift
├── PermissionManagerTests.swift
├── CleanupUndoManagerTests.swift
├── ViewModels/
│   ├── DashboardViewModelTests.swift
│   ├── PhotosViewModelTests.swift
│   └── ...
└── Mocks/
    ├── MockBatteryMonitor.swift
    ├── MockPhotoAnalyzer.swift
    └── ...
```

## Unit Test Template

```swift
import XCTest
@testable import PhoneCare

final class HealthScoreCalculatorTests: XCTestCase {
    var sut: HealthScoreCalculator!
    var mockBatteryMonitor: MockBatteryMonitor!
    var mockStorageAnalyzer: MockStorageAnalyzer!
    
    override func setUp() {
        super.setUp()
        mockBatteryMonitor = MockBatteryMonitor()
        mockStorageAnalyzer = MockStorageAnalyzer()
        sut = HealthScoreCalculator(
            batteryMonitor: mockBatteryMonitor,
            storageAnalyzer: mockStorageAnalyzer
        )
    }
    
    override func tearDown() {
        sut = nil
        mockBatteryMonitor = nil
        mockStorageAnalyzer = nil
        super.tearDown()
    }
    
    // MARK: - Happy Path Tests
    
    func testCalculateScore_allHealthy() {
        // Arrange: Healthy battery + plenty of storage
        mockBatteryMonitor.mockLevel = 80
        mockBatteryMonitor.mockState = .unplugged
        mockStorageAnalyzer.mockAvailableStorage = 20_000_000_000  // 20GB free
        
        // Act
        let score = sut.calculateScore()
        
        // Assert: Score should be in green (51-100)
        XCTAssertGreaterThanOrEqual(score, 51)
        XCTAssertLessThanOrEqual(score, 100)
    }
    
    func testCalculateScore_lowBattery() {
        // Arrange: Low battery (15%)
        mockBatteryMonitor.mockLevel = 15
        mockBatteryMonitor.mockState = .unplugged
        mockStorageAnalyzer.mockAvailableStorage = 5_000_000_000
        
        // Act
        let score = sut.calculateScore()
        
        // Assert: Score affected but not green
        XCTAssertLessThan(score, 80)  // Should be lower due to battery
    }
    
    func testCalculateScore_lowStorage() {
        // Arrange: Less than 1GB free
        mockBatteryMonitor.mockLevel = 80
        mockBatteryMonitor.mockState = .charging
        mockStorageAnalyzer.mockAvailableStorage = 500_000_000  // 500MB
        
        // Act
        let score = sut.calculateScore()
        
        // Assert: Score impacts storage shortage
        XCTAssertLessThan(score, 80)
    }
    
    // MARK: - Edge Cases
    
    func testCalculateScore_zeroStorage() {
        mockStorageAnalyzer.mockAvailableStorage = 0
        let score = sut.calculateScore()
        XCTAssertLessThan(score, 50)  // Should be in warning range
    }
    
    func testCalculateScore_criticalBattery() {
        mockBatteryMonitor.mockLevel = 1
        let score = sut.calculateScore()
        XCTAssertLessThan(score, 30)
    }
    
    func testCalculateScore_perfect() {
        mockBatteryMonitor.mockLevel = 100
        mockBatteryMonitor.mockState = .charging
        mockStorageAnalyzer.mockAvailableStorage = 50_000_000_000
        
        let score = sut.calculateScore()
        XCTAssertGreaterThan(score, 90)
    }
    
    // MARK: - Error Handling
    
    func testCalculateScore_batteryMonitorFails() {
        mockBatteryMonitor.shouldError = true
        
        // Should handle gracefully without crashing
        let score = sut.calculateScore()
        XCTAssertGreaterThan(score, 0)  // Returns default or partial score
    }
}

// MARK: - Mock Dependencies

class MockBatteryMonitor: BatteryMonitor {
    var mockLevel: Int = 100
    var mockState: BatteryState = .unplugged
    var shouldError = false
    
    override func getLevel() -> Int {
        if shouldError { return 0 }
        return mockLevel
    }
    
    override func getState() -> BatteryState {
        if shouldError { return .unknown }
        return mockState
    }
}

class MockStorageAnalyzer: StorageAnalyzer {
    var mockAvailableStorage: Int64 = 10_000_000_000
    var shouldError = false
    
    override func getAvailableStorage() -> Int64 {
        if shouldError { return 0 }
        return mockAvailableStorage
    }
}
```

## Testing Business Logic

### Health Score Algorithm Tests

```swift
func testScoreWeighting() {
    // Health Score = (Battery * 0.3) + (Storage * 0.4) + (Permissions * 0.3)
    mockBatteryMonitor.mockLevel = 100
    mockStorageAnalyzer.mockAvailableStorage = 100_000_000_000
    
    let score = sut.calculateScore()
    // Verify calculation: 100 * 0.3 + 100 * 0.4 + 100 * 0.3 = 100
    XCTAssertEqual(score, 100)
}

func testScoreBoundaries() {
    // Min score
    let minScore = sut.calculateScore(battery: 0, storage: 0, permissions: 0)
    XCTAssertEqual(minScore, 0)
    
    // Max score
    let maxScore = sut.calculateScore(battery: 100, storage: 100, permissions: 100)
    XCTAssertEqual(maxScore, 100)
}
```

### Duplicate Photo Detection Tests

```swift
func testPhotoHashGeneration() {
    // Create test image
    let testImage = UIImage(color: .blue, size: CGSize(width: 100, height: 100))
    
    // Generate hash
    let hash = PhotoAnalyzer.generatePerceptualHash(for: testImage)
    
    // Should be consistent for same image
    let hash2 = PhotoAnalyzer.generatePerceptualHash(for: testImage)
    XCTAssertEqual(hash, hash2)
}

func testPhotoHammingDistance() {
    // Generate similar but not identical images
    let image1 = UIImage(color: .blue, size: CGSize(width: 100, height: 100))
    let image2 = UIImage(color: UIColor(red: 0, green: 0, blue: 0.99, alpha: 1), size: CGSize(width: 100, height: 100))
    
    let hash1 = PhotoAnalyzer.generatePerceptualHash(for: image1)
    let hash2 = PhotoAnalyzer.generatePerceptualHash(for: image2)
    
    // Distance should be low for similar images
    let distance = PhotoAnalyzer.hammingDistance(hash1, hash2)
    XCTAssertLessThan(distance, 20)  // Threshold for "duplicate"
}

func testPhotoDeduplication_findsDuplicates() {
    // Arrange: Set up duplicate group
    let photos = [
        createTestPhoto(id: "1", perceptualHash: "abc123"),
        createTestPhoto(id: "2", perceptualHash: "abc456"),  // Similar hash
        createTestPhoto(id: "3", perceptualHash: "xyz789"),  // Different
    ]
    
    // Act
    let groups = PhotoAnalyzer.groupDuplicates(photos)
    
    // Assert: Should find 1 duplicate group + 1 single
    XCTAssertEqual(groups.count, 2)
    XCTAssertEqual(groups[0].count, 2)  // Duplicates
    XCTAssertEqual(groups[1].count, 1)  // Single
}
```

### ViewModel State Tests

```swift
@MainActor
func testPhotosViewModel_loadPhotos() async {
    // Arrange
    let viewModel = PhotosViewModel(photoAnalyzer: mockAnalyzer)
    mockAnalyzer.mockPhotos = [createTestPhoto(id: "1")]
    
    // Act
    await viewModel.loadPhotos()
    
    // Assert
    XCTAssertEqual(viewModel.loadingState, .success)
    XCTAssertEqual(viewModel.photos.count, 1)
}

@MainActor
func testPhotosViewModel_deletePhotos() async {
    // Arrange
    let viewModel = PhotosViewModel(photoAnalyzer: mockAnalyzer)
    let photo = createTestPhoto(id: "1")
    
    // Act
    await viewModel.deletePhotos([photo])
    
    // Assert: Should be undoable
    XCTAssertTrue(viewModel.canUndo)
    
    // Undo
    await viewModel.undo()
    XCTAssertFalse(viewModel.canUndo)
}
```

## Mocking Patterns

### Dependency Injection
```swift
// ✓ CORRECT: Easy to mock
class PhotosViewModel {
    let photoAnalyzer: PhotoAnalyzer
    
    init(photoAnalyzer: PhotoAnalyzer = .shared) {
        self.photoAnalyzer = photoAnalyzer
    }
}

// In tests
let mockAnalyzer = MockPhotoAnalyzer()
let viewModel = PhotosViewModel(photoAnalyzer: mockAnalyzer)
```

### Protocol Mocking
```swift
protocol BatteryMonitor {
    func getLevel() -> Int
    func getState() -> BatteryState
}

class MockBatteryMonitor: BatteryMonitor {
    var level: Int = 100
    
    func getLevel() -> Int { level }
    func getState() -> BatteryState { .unplugged }
}
```

## Test Coverage Goals

| Component | Target | Type |
|-----------|--------|------|
| HealthScoreCalculator | 100% | Unit |
| PhotoAnalyzer | 95% | Unit + Edge cases |
| ContactAnalyzer | 95% | Unit + Edge cases |
| StorageAnalyzer | 90% | Unit |
| ViewModels | 80% | Unit + state transitions |
| UI Views | N/A | Manual + snapshots |

## Running Tests

```bash
# Run all tests
xcodebuild test -scheme PhoneCare -destination 'generic/platform=iOS'

# Run specific test class
xcodebuild test -scheme PhoneCare \
  -testClassName HealthScoreCalculatorTests

# Run with coverage
xcodebuild test -scheme PhoneCare \
  -destination 'generic/platform=iOS' \
  -enableCodeCoverage YES

# Generate coverage report
xcodebuild test -scheme PhoneCare \
  -resultBundlePath TestResults \
  -enableCodeCoverage YES

# View coverage
open TestResults.xcresult  # Opens Xcode Report
```

## Test Best Practices

- **Test one thing per test:** Clear name, single assertion focus
- **AAA Pattern:** Arrange, Act, Assert
- **Test edge cases:** Boundaries, errors, empty states
- **Mock dependencies:** Isolate the unit being tested
- **Don't test framework code:** Assume Apple's code works
- **Test business logic:** Algorithms, calculations, state changes
- **Avoid flaky tests:** No timing dependencies, no random data
- **Keep tests fast:** <1 second per test ideal

## Common Test Pitfalls

| Pitfall | Problem | Fix |
|---------|---------|-----|
| Testing framework code | Tests brittle, slow | Test only your code |
| Shared mutable state | Tests interfere | Clean in tearDown |
| Hard to understand test | Future devs confused | Clear naming, comments |
| Async race conditions | Tests flaky | Use async/await, XCTestExpectation |
| Over-mocking | Test becomes meaningless | Mock only dependencies |

---

**Use This Skill When:**
- Writing unit tests for new features
- Refactoring with test safety
- Debugging test failures
- Calculating code coverage
- Mentoring on testing practices
