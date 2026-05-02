---
name: performance-profiling
user-invocable: true
description: "Use when: profiling CPU, memory, and battery usage; identifying bottlenecks; optimizing scans; measuring app performance; using Xcode Instruments; setting performance budgets."
---

# PhoneCare Performance Profiling Skill

Performance optimization, profiling tools, and bottleneck identification.

## Performance Budget

| Metric | Target | Pass | Consequence |
|--------|--------|------|-------------|
| **Photo scan time** | <5s (1000 photos) | <10s | Blocks feature if too slow |
| **Contact scan time** | <1s (500 contacts) | <2s | Blocks feature if too slow |
| **Health score calc** | <500ms | <1s | UI lags if slower |
| **Peak memory** | <100MB | <200MB | Crashes on older devices |
| **Battery per scan** | <2% per full scan | <5% | Drains device if excessive |
| **Startup time** | <2s to main screen | <3s | Poor user experience |

## Xcode Instruments: The Essential Profiling Tool

### Launching Instruments

```bash
# Via Xcode
Xcode → Product → Profile (⌘I)

# Or launch separately
open /Applications/Xcode.app/Contents/Applications/Instruments.app
```

### Key Instruments for PhoneCare

| Instrument | Measures | When to Use |
|------------|----------|------------|
| **System Trace** | CPU, memory, threads, disk | Overall performance |
| **Memory Profiler** | Heap allocations, object count | Memory leaks, bloat |
| **Core Animation** | Frame rate, dropped frames | UI smoothness |
| **Core Data** | Fetch performance, cache hits | Database performance |
| **Energy Impact** | CPU, GPU, disk, network usage | Battery drain |

### Memory Profiling Workflow

1. **Attach Instruments**
   - Product → Profile → Memory
   - Select iPhone in simulator/device
   - Wait for app to load

2. **Perform Action**
   - Trigger photo scan
   - Let scan complete
   - Watch memory graph

3. **Analyze Growth**
   - Memory spike during scan: Normal ✓
   - Memory stays high after scan: Leak ❌
   - Memory returns to baseline: Good ✓

4. **Identify Leaks**
   - Red flag: "Leaked" in Instruments
   - Inspect backtrace
   - Fix: Use `[weak self]` in closures

### Example: Finding Memory Leak

```
Instruments Screenshot:
├── 200MB at scan start
├── 450MB at peak (scan progress)
├── 380MB after scan ends  ← Should drop to ~200MB
└── Still 380MB 30 seconds later  ← LEAK DETECTED
```

**Potential causes:**
- Photo cache not released
- `[weak self]` missing in async closure
- Observer not removed
- Circular reference

## CPU Profiling

### Using Instruments: System Trace

1. Profile → System Trace
2. Start recording
3. Trigger photo scan
4. Stop after scan completes
5. Analyze CPU timeline:
   - Green = efficient
   - Red spikes = bottleneck

### CPU Targets

```
Scan Performance Benchmarks:
├── 100 photos: <100ms
├── 1,000 photos: <5 seconds
├── 5,000 photos: <20 seconds
└── 10,000 photos: <40 seconds
```

## Battery Profiling

### Energy Impact Instrument

1. Profile → Energy Impact
2. Run full photo scan
3. Check battery drain
4. Target: <2% battery per scan

**Battery-draining patterns:**
- Constant CPU usage (no idle): Bad
- Frequent disk I/O: Bad
- Unnecessary screen on: Bad
- Background processing: Acceptable if batched

## Profiling Code: Manual Measurement

```swift
import Foundation

class PerformanceTimer {
    private let label: String
    private let startTime: CFTimeInterval
    
    init(label: String) {
        self.label = label
        self.startTime = CACurrentMediaTime()
    }
    
    func end() {
        let duration = CACurrentMediaTime() - startTime
        print("⏱️ \(label): \(String(format: "%.2fms", duration * 1000))")
    }
}

// Usage:
let timer = PerformanceTimer(label: "Photo scan")
let results = PhotoAnalyzer.scanForDuplicates()
timer.end()

// Output: ⏱️ Photo scan: 4523.45ms
```

### Memory Measurement

```swift
func measureMemory(label: String) {
    var info = task_vm_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size)/4
    
    let kerr = withUnsafeMutablePointer(to: &info) {
        task_info(mach_task_self_,
                  task_flavor_t(TASK_VM_INFO),
                  $0.withMemoryRebound(to: integer_t.self, capacity: 1) { $0 },
                  &count)
    }
    
    guard kerr == KERN_SUCCESS else { return }
    
    let usedMemory = Double(info.phys_footprint) / 1_024_000  // Convert to MB
    print("💾 \(label): \(String(format: "%.1f MB", usedMemory))")
}

// Usage in scan:
measureMemory(label: "Before scan")
let results = PhotoAnalyzer.scanForDuplicates()
measureMemory(label: "After scan")
```

## Optimization Strategies

### 1. Batch Processing (Reduce UI Hangs)

**WRONG - Blocks UI:**
```swift
for photo in photos {
    let hash = generateHash(photo)  // ❌ Main thread blocks
    process(hash)
}
```

**CORRECT - Background thread:**
```swift
DispatchQueue.global().async {
    for photo in photos {
        let hash = generateHash(photo)
        DispatchQueue.main.async {
            self?.updateUI(with: hash)  // Update UI in batches
        }
    }
}
```

### 2. Caching (Avoid Redundant Work)

```swift
class PhotoHashCache {
    private var cache: [String: String] = [:]
    
    func getHash(for photoID: String) -> String? {
        // Return cached hash if available
        return cache[photoID]
    }
    
    func setHash(_ hash: String, for photoID: String) {
        cache[photoID] = hash
    }
}
```

### 3. Lazy Loading (Process When Needed)

```swift
// DON'T load all photos at once
let allPhotos = PHAsset.fetchAssets(with: .image, options: nil)  // ❌ Slow

// DO: Load in chunks
let fetchOptions = PHFetchOptions()
fetchOptions.fetchLimit = 100  // ✓ Load first 100, then next 100
let photoChunk = PHAsset.fetchAssets(with: .image, options: fetchOptions)
```

### 4. Algorithm Optimization (Reduce Complexity)

**WRONG - O(n²) comparison:**
```swift
for i in photos {
    for j in photos {
        if areDuplicate(i, j) { /* merge */ }  // ❌ 1M comparisons for 1k photos
    }
}
```

**CORRECT - O(n log n) grouping:**
```swift
let groups = groupByHash(photos)  // ✓ Uses hash buckets, much faster
```

## Profiling Checklist

Before shipping:

- [ ] **Memory:** Peak <100MB during scan, returns to baseline after
- [ ] **CPU:** Scan time <target (5s for 1000 photos)
- [ ] **Battery:** <2% drain per scan
- [ ] **Startup:** <2 seconds to main screen
- [ ] **No memory leaks:** Instruments shows no red flags
- [ ] **Smooth scrolling:** Core Animation shows 60fps (or 120fps for new devices)
- [ ] **Background thread:** All heavy work off main thread

## Performance Testing on Device

### Recommended Test Devices

| Device | iOS | Use For |
|--------|-----|---------|
| **iPhone 11** | Latest | Baseline (oldest supported) |
| **iPhone 13** | Latest | Mid-range performance |
| **iPhone 15** | Latest | High-end performance |

**Test on iPhone 11 first** — if it passes, newer devices will fly.

### Real-World Test Scenarios

1. **Large Photo Library Test**
   - Add 5,000+ photos to device
   - Trigger duplicate scan
   - Measure time + memory + battery

2. **Low Memory Test**
   - Load many apps to consume RAM
   - Trigger scan with limited memory
   - App shouldn't crash

3. **Thermal Stress Test**
   - Run continuous scans for 10+ minutes
   - Watch for thermal throttling
   - Core count decreases → slower scans

## Red Flags (Performance Anti-Patterns)

- ❌ Heavy work on main thread (freezes UI)
- ❌ Creating 1000s of objects in loop (memory spike)
- ❌ Loading entire photo library at once (slow startup)
- ❌ Unused image caches (memory leak)
- ❌ Observer not removed (memory leak)
- ❌ Synchronous network calls (not in PhoneCare, but if added)
- ❌ Animations on every frame (battery drain)

## Optimization Examples

### Before (Slow)
```swift
func scanPhotos(_ photos: [Photo]) -> [[Photo]] {
    // Load all photos into memory at once
    let loaded = photos.map { loadImage($0) }
    
    // Calculate hashes sequentially on main thread
    for photo in loaded {
        let hash = expensiveHashCalculation(photo)
        updateUI(with: hash)  // Main thread UI update
    }
    
    // Compare all pairs (O(n²))
    for i in loaded {
        for j in loaded {
            comparePhotos(i, j)  // Redundant comparisons
        }
    }
}
```

### After (Fast)
```swift
func scanPhotos(_ photos: [Photo]) -> [[Photo]] {
    // Load hashes in background
    var hashCache: [String: String] = [:]
    
    DispatchQueue.global().async { [weak self] in
        for (index, photo) in photos.enumerated() {
            // Check cache first
            if hashCache[photo.id] != nil { continue }
            
            // Calculate hash once
            let hash = expensiveHashCalculation(photo)
            hashCache[photo.id] = hash
            
            // Update UI in batches (every 50 photos)
            if index % 50 == 0 {
                DispatchQueue.main.async {
                    self?.updateProgress(index, photos.count)
                }
            }
        }
        
        // Group by hash (O(n log n))
        let groups = self?.groupByHash(hashCache, threshold: 15)
        
        DispatchQueue.main.async {
            self?.displayResults(groups)
        }
    }
}
```

## Performance Regression Testing

### Automated Benchmarks

```swift
func testPhotoScanPerformance() {
    let photos = createTestPhotos(count: 1000)
    
    measure {
        _ = PhotoAnalyzer.scanForDuplicates(photos)
    }
    // Xcode will flag if this regresses significantly
}
```

### GitHub Actions Performance Report

```yaml
      - name: Run performance tests
        run: |
          xcodebuild test -scheme PhoneCare \
            -testClassName PerformanceTests \
            -resultBundlePath Results
          
          # Extract timing results
          grep "Execution Time" Results.xcresult
```

---

**Use This Skill When:**
- Optimizing photo scan performance
- Debugging memory leaks
- Measuring battery impact
- Profiling startup time
- Setting performance budgets
- Analyzing CPU usage
