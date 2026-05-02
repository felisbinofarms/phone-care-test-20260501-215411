---
name: photokit-duplicate-detection
user-invocable: true
description: "Use when: detecting duplicate or similar photos, selecting hash algorithm (PHASH vs ML), comparing photos, grouping duplicates, optimizing scan performance, handling edge cases."
---

# PhotoKit Duplicate Detection Skill

Algorithm selection, implementation, and optimization for detecting duplicate/similar photos.

## Algorithm Decision Matrix

| Approach | CPU Impact | Accuracy | iOS Min | Offline | Chosen |
|----------|-----------|----------|---------|---------|--------|
| **Perceptual Hash (PHASH)** | Low | 90% | iOS 17 | ✓ Yes | ✓ MVP |
| **ML Model (Vision)** | Medium | 98% | iOS 18 | ✓ Yes | Future |
| **File Hash (MD5)** | Low | 100% (identical only) | iOS 17 | ✓ Yes | Fallback |
| **EXIF Metadata** | Low | 60% (date/location) | iOS 17 | ✓ Yes | Supplement |

**MVP Selection: Perceptual Hash (PHASH)**
- Efficient: O(1) comparison after hashing
- Effective: Catches visually similar photos
- Works on iOS 17+
- Fully on-device

## Perceptual Hash (PHASH) Algorithm

```swift
import UIKit

struct PhotoAnalyzer {
    /// Generate perceptual hash for an image
    /// - Parameter image: Source image
    /// - Returns: 64-bit hash as hex string
    static func generatePerceptualHash(for image: UIImage) -> String {
        // Resize to 8x8 (small enough for fast comparison)
        let resized = image.resized(to: CGSize(width: 8, height: 8))
        
        // Convert to grayscale
        let grayscale = resized.toGrayscale()
        
        // Calculate average brightness
        let pixels = grayscale.getPixels()
        let average = pixels.reduce(0, +) / pixels.count
        
        // Generate 64-bit hash (8x8 = 64 bits)
        var hash: UInt64 = 0
        for (index, pixel) in pixels.enumerated() {
            if pixel > average {
                hash |= (1 << index)
            }
        }
        
        return String(format: "%016llx", hash)
    }
    
    /// Calculate Hamming distance between two hashes
    /// - Returns: Number of differing bits (0–64)
    static func hammingDistance(_ hash1: String, _ hash2: String) -> Int {
        guard hash1.count == hash2.count else { return Int.max }
        
        var distance = 0
        for (bit1, bit2) in zip(hash1, hash2) {
            if bit1 != bit2 {
                distance += 1
            }
        }
        return distance
    }
    
    /// Determine if two photos are duplicates
    /// - Parameter threshold: Max Hamming distance (0–64, default 15)
    static func areDuplicates(_ hash1: String, _ hash2: String, threshold: Int = 15) -> Bool {
        return hammingDistance(hash1, hash2) <= threshold
    }
}

// MARK: - Image Processing Helpers

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        self.draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
    
    func toGrayscale() -> UIImage {
        guard let cgImage = cgImage else { return self }
        
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(CIImage(cgImage: cgImage), forKey: kCIInputImageKey)
        filter?.setValue(0, forKey: kCIInputSaturationKey)
        
        guard let output = filter?.outputImage else { return self }
        let context = CIContext()
        guard let processed = context.createCGImage(output, from: output.extent) else { return self }
        
        return UIImage(cgImage: processed)
    }
    
    func getPixels() -> [CGFloat] {
        guard let cgImage = cgImage else { return [] }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        
        var pixels: [CGFloat] = []
        let data = UnsafeMutablePointer<UInt8>.allocate(capacity: height * bytesPerRow)
        defer { data.deallocate() }
        
        let context = CGContext(
            data: data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        )
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        for i in 0..<(width * height) {
            pixels.append(CGFloat(data[i * bytesPerPixel]) / 255.0)
        }
        
        return pixels
    }
}
```

## Duplicate Detection: Grouping Algorithm

```swift
struct PhotoGroup {
    let photos: [Photo]
    let similarity: Double
}

extension PhotoAnalyzer {
    /// Group photos by duplicate similarity
    /// - Parameter photos: List of photos with hashes
    /// - Returns: Groups of similar photos + singles
    static func groupDuplicates(
        _ photos: [Photo],
        threshold: Int = 15
    ) -> [[Photo]] {
        var groups: [[Photo]] = []
        var processed = Set<String>()
        
        for photo in photos {
            guard !processed.contains(photo.id) else { continue }
            
            // Start new group with this photo
            var group = [photo]
            processed.insert(photo.id)
            
            // Find similar photos
            for other in photos {
                guard !processed.contains(other.id) else { continue }
                
                let distance = hammingDistance(photo.hash, other.hash)
                if distance <= threshold {
                    group.append(other)
                    processed.insert(other.id)
                }
            }
            
            groups.append(group)
        }
        
        // Sort: groups with >1 photo first (duplicates)
        return groups.sorted { ($0.count > 1) ? true : false }
    }
}
```

## PhotoKit Integration

```swift
import Photos

class PhotoAnalyzer {
    func scanForDuplicates(completion: @escaping ([[Photo]]) -> Void) {
        DispatchQueue.global().async { [weak self] in
            let photos = self?.fetchPhotos() ?? []
            
            // Generate hashes
            let photosWithHashes = photos.map { photo in
                Photo(
                    id: photo.localIdentifier,
                    image: photo.image,
                    hash: Self.generatePerceptualHash(for: photo.image),
                    createdDate: photo.creationDate
                )
            }
            
            // Group duplicates
            let groups = Self.groupDuplicates(photosWithHashes)
            
            DispatchQueue.main.async {
                completion(groups)
            }
        }
    }
    
    private func fetchPhotos() -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let result = PHAsset.fetchAssets(with: .image, options: options)
        var assets: [PHAsset] = []
        
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        return assets
    }
}
```

## Performance Optimization

### Caching Hashes

```swift
class PhotoHashCache {
    private var cache: [String: String] = [:]
    private let queue = DispatchQueue(label: "com.phonecare.hash-cache", attributes: .concurrent)
    
    func getHash(for photoID: String) -> String? {
        return queue.sync { cache[photoID] }
    }
    
    func setHash(_ hash: String, for photoID: String) {
        queue.async(flags: .barrier) {
            self.cache[photoID] = hash
        }
    }
}
```

### Incremental Scanning

```swift
func scanPhotosIncremental(
    previousHashes: [String: String],
    progressCallback: @escaping (Int, Int) -> Void
) {
    let currentPhotos = fetchPhotos()
    var newHashes = previousHashes
    
    for (index, photo) in currentPhotos.enumerated() {
        if newHashes[photo.id] == nil {
            newHashes[photo.id] = generatePerceptualHash(for: photo.image)
        }
        progressCallback(index + 1, currentPhotos.count)
    }
    
    return groupDuplicates(newHashes)
}
```

### Scan Time Targets
- **1,000 photos:** <5 seconds
- **5,000 photos:** <20 seconds
- **10,000 photos:** <40 seconds

## Edge Cases

| Edge Case | Solution |
|-----------|----------|
| Same photo, different sizes | PHASH handles resizing automatically |
| Rotated photos | Need to normalize rotation first |
| Edited photos | PHASH may not match (depends on edits) |
| Screenshots (different metadata) | PHASH will catch if visually identical |
| Screenshots of same photo | Will be detected as duplicates |
| Photos from different albums | Scope across entire library |
| Sync'd photos (iCloud) | PhOTKit abstracts this, works transparently |
| Video files in library | Filter by .image type only |

## Threshold Tuning

**Hamming distance threshold trade-offs:**

| Threshold | False Positives | False Negatives | Typical Use |
|-----------|-----------------|-----------------|------------|
| 0–5 | Rare | Many misses | Too strict |
| **10–15** | **Few** | **Few** | **MVP (Default)** |
| 20–25 | Moderate | Few | Aggressive |
| >30 | Many | Almost none | Too loose |

**Recommendation: Start at threshold=15, adjust based on QA feedback**

## Testing the Algorithm

```swift
func testPhotoGrouping() {
    // Create test images
    let original = createTestImage(color: .blue, size: CGSize(width: 100, height: 100))
    let brightBlue = createTestImage(color: .blue.withAlphaComponent(0.9), size: CGSize(width: 100, height: 100))
    let different = createTestImage(color: .red, size: CGSize(width: 100, height: 100))
    
    let photos = [
        Photo(id: "1", image: original, hash: generateHash(original)),
        Photo(id: "2", image: brightBlue, hash: generateHash(brightBlue)),
        Photo(id: "3", image: different, hash: generateHash(different))
    ]
    
    let groups = PhotoAnalyzer.groupDuplicates(photos, threshold: 15)
    
    // Should find 1 group (similar) + 1 single (different)
    assert(groups.count == 2)
    assert(groups[0].count == 2)  // Duplicates
    assert(groups[1].count == 1)  // Single
}
```

## Implementation Checklist

- [ ] Implement PHASH algorithm with UIImage resizing
- [ ] Create grouping algorithm (O(n²) comparison)
- [ ] Integrate with PhotoKit (fetch photos)
- [ ] Add caching for hash results
- [ ] Implement incremental scanning
- [ ] Background thread: All scans on DispatchQueue.global()
- [ ] Progress callback: Update UI every 50 photos
- [ ] Test on device: 1000+ photos < 5 seconds
- [ ] Edge case tests: Rotations, different sizes, metadata
- [ ] QA: Verify threshold=15 catches expected duplicates
- [ ] UX: Show "Scan in progress" spinner + time estimate

---

**Use This Skill When:**
- Implementing photo duplicate detection
- Tuning duplicate detection algorithm
- Performance optimization for large photo libraries
- Debugging false positives/negatives
- Writing tests for photo analysis
