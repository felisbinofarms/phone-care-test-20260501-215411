import Testing
import Foundation
@testable import PhoneCare

@Suite("StorageAnalyzer")
struct StorageAnalyzerTests {

    // MARK: - StorageCategoryData

    @Test("formattedSize returns a non-empty string for a typical size")
    func formattedSize_typical() {
        let category = StorageCategoryData(
            id: "photos",
            name: "Photos & Videos",
            icon: "photo.fill",
            sizeInBytes: 1_073_741_824, // 1 GB
            color: "pcPrimary"
        )
        #expect(!category.formattedSize.isEmpty)
    }

    @Test("formattedSize handles zero bytes without crashing")
    func formattedSize_zero() {
        let category = StorageCategoryData(
            id: "available",
            name: "Available",
            icon: "checkmark.circle.fill",
            sizeInBytes: 0,
            color: "pcAccent"
        )
        #expect(!category.formattedSize.isEmpty)
    }

    @Test("StorageCategoryData id is preserved")
    func categoryID_preserved() {
        let category = StorageCategoryData(
            id: "apps",
            name: "Apps",
            icon: "square.grid.2x2.fill",
            sizeInBytes: 500_000_000,
            color: "pcAccent"
        )
        #expect(category.id == "apps")
    }

    // MARK: - StorageAnalysisResult: usedBytes

    @Test("usedBytes equals total minus available")
    func usedBytes_typical() {
        let result = StorageAnalysisResult(
            totalBytes: 128_000_000_000,
            availableBytes: 30_000_000_000,
            categories: []
        )
        #expect(result.usedBytes == 98_000_000_000)
    }

    @Test("usedBytes is zero when storage is completely free")
    func usedBytes_completelyFree() {
        let result = StorageAnalysisResult(
            totalBytes: 100,
            availableBytes: 100,
            categories: []
        )
        #expect(result.usedBytes == 0)
    }

    @Test("usedBytes equals total when no space is available")
    func usedBytes_full() {
        let result = StorageAnalysisResult(
            totalBytes: 100,
            availableBytes: 0,
            categories: []
        )
        #expect(result.usedBytes == 100)
    }

    // MARK: - StorageAnalysisResult: usedPercentage

    @Test("usedPercentage with 25% free returns 75%")
    func usedPercentage_75() {
        let result = StorageAnalysisResult(
            totalBytes: 100,
            availableBytes: 25,
            categories: []
        )
        #expect(result.usedPercentage == 75.0)
    }

    @Test("usedPercentage returns 0 when total is zero")
    func usedPercentage_zeroTotal() {
        let result = StorageAnalysisResult(
            totalBytes: 0,
            availableBytes: 0,
            categories: []
        )
        #expect(result.usedPercentage == 0.0)
    }

    @Test("usedPercentage returns 100 when device is full")
    func usedPercentage_full() {
        let result = StorageAnalysisResult(
            totalBytes: 100,
            availableBytes: 0,
            categories: []
        )
        #expect(result.usedPercentage == 100.0)
    }

    @Test("usedPercentage returns 0 when nothing is used")
    func usedPercentage_empty() {
        let result = StorageAnalysisResult(
            totalBytes: 200,
            availableBytes: 200,
            categories: []
        )
        #expect(result.usedPercentage == 0.0)
    }

    // MARK: - StorageAnalysisResult: formatted strings

    @Test("Formatted strings are non-empty for a typical device")
    func formattedStrings_nonEmpty() {
        let result = StorageAnalysisResult(
            totalBytes: 64_000_000_000,
            availableBytes: 20_000_000_000,
            categories: []
        )
        #expect(!result.formattedTotal.isEmpty)
        #expect(!result.formattedAvailable.isEmpty)
        #expect(!result.formattedUsed.isEmpty)
    }

    // MARK: - StorageAnalysisResult: categories

    @Test("Categories are preserved in the result")
    func categories_preserved() {
        let cat = StorageCategoryData(
            id: "photos",
            name: "Photos",
            icon: "photo",
            sizeInBytes: 500_000_000,
            color: "pcPrimary"
        )
        let result = StorageAnalysisResult(
            totalBytes: 1_000_000_000,
            availableBytes: 500_000_000,
            categories: [cat]
        )
        #expect(result.categories.count == 1)
        #expect(result.categories.first?.id == "photos")
        #expect(result.categories.first?.sizeInBytes == 500_000_000)
    }

    @Test("Empty categories produce a valid result")
    func categories_empty() {
        let result = StorageAnalysisResult(
            totalBytes: 0,
            availableBytes: 0,
            categories: []
        )
        #expect(result.categories.isEmpty)
    }

    // MARK: - Edge cases

    @Test("formattedSize handles very large values (1 TB)")
    func formattedSize_veryLarge() {
        let category = StorageCategoryData(
            id: "system",
            name: "System",
            icon: "gear",
            sizeInBytes: 1_099_511_627_776, // 1 TB
            color: "pcPrimary"
        )
        #expect(!category.formattedSize.isEmpty)
    }

    @Test("usedPercentage for small fractional usage")
    func usedPercentage_smallFraction() {
        let result = StorageAnalysisResult(
            totalBytes: 1_000_000,
            availableBytes: 999_999,
            categories: []
        )
        // 1 byte used out of 1 million — very small percentage
        #expect(result.usedPercentage >= 0)
        #expect(result.usedPercentage < 1)
    }
}
