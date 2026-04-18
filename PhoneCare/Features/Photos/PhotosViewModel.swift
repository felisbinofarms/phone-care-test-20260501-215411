import SwiftUI
import SwiftData
import Photos

enum PhotoCategory: String, CaseIterable, Identifiable {
    case duplicates = "Duplicates"
    case screenshots = "Screenshots"
    case blurry = "Blurry"
    case largeVideos = "Large Videos"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .duplicates:  return "plus.square.on.square"
        case .screenshots: return "rectangle.portrait"
        case .blurry:      return "camera.metering.unknown"
        case .largeVideos: return "video.fill"
        }
    }
}

struct ScreenshotAgeGroup: Identifiable {
    let title: String
    let ids: [String]
    var id: String { title }
}

@MainActor
@Observable
final class PhotosViewModel {

    // MARK: - Dependencies

    private let analyzer = PhotoAnalyzer()

    // MARK: - State

    var selectedCategory: PhotoCategory = .duplicates
    private(set) var isScanning: Bool = false
    private(set) var scanComplete: Bool = false
    private(set) var permissionDenied: Bool = false

    // Group data
    private(set) var duplicateGroups: [[String]] = []
    private(set) var screenshotIDs: [String] = []
    private(set) var blurryIDs: [String] = []
    private(set) var largeVideoIDs: [String] = []

    // Selection
    var selectedPhotoIDs: Set<String> = []

    // Batch delete
    var showBatchDeleteSheet: Bool = false
    private(set) var lastDeletedCount: Int = 0
    private(set) var lastDeletedSize: Int64 = 0
    var showUndoToast: Bool = false

    // Premium gating
    private(set) var freeGroupLimit: Int = 3

    // MARK: - Progress (pass-through from analyzer)

    var scanProgress: Double { analyzer.progress }
    var scanStatusMessage: String { analyzer.statusMessage }

    // MARK: - Computed

    var currentResultCount: Int {
        switch selectedCategory {
        case .duplicates:  return duplicateGroups.count
        case .screenshots: return screenshotIDs.count
        case .blurry:      return blurryIDs.count
        case .largeVideos: return largeVideoIDs.count
        }
    }

    var currentCategoryDescription: String {
        switch selectedCategory {
        case .duplicates:
            let count = duplicateGroups.reduce(0) { $0 + $1.count }
            return count == 0 ? "No duplicates found" : "\(duplicateGroups.count) groups with \(count) photos"
        case .screenshots:
            return screenshotIDs.isEmpty ? "No screenshots found" : "\(screenshotIDs.count) screenshots"
        case .blurry:
            return blurryIDs.isEmpty ? "No blurry photos found" : "\(blurryIDs.count) blurry photos"
        case .largeVideos:
            return largeVideoIDs.isEmpty ? "No large videos found" : "\(largeVideoIDs.count) large videos"
        }
    }

    var selectedCount: Int { selectedPhotoIDs.count }

    var hasResults: Bool { currentResultCount > 0 }

    // MARK: - Screenshot Age Groups

    func screenshotsByAge() -> [ScreenshotAgeGroup] {
        guard !screenshotIDs.isEmpty else { return [] }

        let now = Date()
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now)!

        var thisWeek: [String] = []
        var lastMonth: [String] = []
        var olderThan30: [String] = []
        var olderThan90: [String] = []

        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: screenshotIDs, options: nil)
        fetchResult.enumerateObjects { asset, _, _ in
            let id = asset.localIdentifier
            guard let date = asset.creationDate else {
                olderThan90.append(id)
                return
            }
            if date >= oneWeekAgo {
                thisWeek.append(id)
            } else if date >= oneMonthAgo {
                lastMonth.append(id)
            } else if date >= threeMonthsAgo {
                olderThan30.append(id)
            } else {
                olderThan90.append(id)
            }
        }

        var groups: [ScreenshotAgeGroup] = []
        if !thisWeek.isEmpty {
            groups.append(ScreenshotAgeGroup(title: "This Week", ids: thisWeek))
        }
        if !lastMonth.isEmpty {
            groups.append(ScreenshotAgeGroup(title: "Last Month", ids: lastMonth))
        }
        if !olderThan30.isEmpty {
            groups.append(ScreenshotAgeGroup(title: "Older than 30 Days", ids: olderThan30))
        }
        if !olderThan90.isEmpty {
            groups.append(ScreenshotAgeGroup(title: "Older than 90 Days", ids: olderThan90))
        }
        return groups
    }

    func selectAllInAgeGroup(_ group: ScreenshotAgeGroup) {
        selectedPhotoIDs.formUnion(group.ids)
    }

    // MARK: - Load

    func load(dataManager: DataManager) {
        do {
            let caches = try dataManager.fetch(
                PhotoScanCache.self,
                sortBy: [SortDescriptor(\.scanDate, order: .reverse)],
                fetchLimit: 1
            )
            if let cache = caches.first {
                duplicateGroups = cache.decodedDuplicateGroups()
                screenshotIDs = cache.decodedScreenshotIDs()
                blurryIDs = cache.decodedBlurryIDs()
                largeVideoIDs = cache.decodedLargeVideoIDs()
                scanComplete = true
            }
        } catch {
            // Show empty state
        }
    }

    // MARK: - Scan

    func startScan(dataManager: DataManager) {
        isScanning = true
        permissionDenied = false
        Task {
            let analysisResult = await analyzer.analyze()

            let authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            guard authStatus == .authorized || authStatus == .limited else {
                isScanning = false
                permissionDenied = true
                return
            }

            await analyzer.saveCache(to: dataManager, analysisResult: analysisResult)
            updateScanResult(dataManager: dataManager, analysisResult: analysisResult)

            duplicateGroups = analysisResult.duplicateGroups.map { $0.assetIdentifiers }
            screenshotIDs = analysisResult.screenshotIdentifiers
            blurryIDs = analysisResult.blurryIdentifiers
            largeVideoIDs = analysisResult.largeVideoIdentifiers

            isScanning = false
            scanComplete = true
        }
    }

    // MARK: - Selection

    func toggleSelection(_ id: String) {
        if selectedPhotoIDs.contains(id) {
            selectedPhotoIDs.remove(id)
        } else {
            selectedPhotoIDs.insert(id)
        }
    }

    func selectAll(in ids: [String]) {
        selectedPhotoIDs.formUnion(ids)
    }

    func deselectAll() {
        selectedPhotoIDs.removeAll()
    }

    // MARK: - Batch Delete

    func prepareBatchDelete() {
        guard !selectedPhotoIDs.isEmpty else { return }
        showBatchDeleteSheet = true
    }

    func confirmBatchDelete() {
        lastDeletedCount = selectedPhotoIDs.count
        lastDeletedSize = Int64(selectedPhotoIDs.count) * 3_500_000 // Estimate ~3.5MB per photo
        selectedPhotoIDs.removeAll()
        showBatchDeleteSheet = false
        showUndoToast = true
    }

    func undoDelete() {
        showUndoToast = false
        // Undo handled by CleanupUndoManager
    }

    // MARK: - Premium Helpers

    func isGroupAccessible(index: Int, isPremium: Bool) -> Bool {
        isPremium || index < freeGroupLimit
    }

    func visibleDuplicateGroups(isPremium: Bool) -> [[String]] {
        if isPremium { return duplicateGroups }
        return Array(duplicateGroups.prefix(freeGroupLimit))
    }

    // MARK: - Persistence

    private func updateScanResult(dataManager: DataManager, analysisResult: PhotoAnalysisResult) {
        do {
            if let existing = try dataManager.latestScanResult() {
                existing.photoCount = analysisResult.totalPhotos
                existing.duplicatePhotoCount = analysisResult.duplicateCount
                existing.duplicatePhotoSize = analysisResult.estimatedDuplicateSavings
                try dataManager.saveContext()
            } else {
                let scanResult = ScanResult(
                    photoCount: analysisResult.totalPhotos,
                    duplicatePhotoCount: analysisResult.duplicateCount,
                    duplicatePhotoSize: analysisResult.estimatedDuplicateSavings
                )
                try dataManager.save(scanResult)
            }
        } catch {
            // Persistence failure shouldn't block scan results from showing
        }
    }
}
