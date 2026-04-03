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
