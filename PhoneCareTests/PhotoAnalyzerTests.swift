import Testing
import Foundation
@testable import PhoneCare

@Suite("PhotoAnalyzer")
struct PhotoAnalyzerTests {

    // MARK: - DuplicateGroup: count

    @Test("count returns the total number of identifiers in the group")
    func duplicateGroup_count() {
        let group = DuplicateGroup(
            id: "g1",
            assetIdentifiers: ["a", "b", "c"],
            suggestedKeepIdentifier: "a",
            estimatedSavingsBytes: 1_000_000
        )
        #expect(group.count == 3)
    }

    @Test("count returns 1 for a single-asset group")
    func duplicateGroup_countSingle() {
        let group = DuplicateGroup(
            id: "g1",
            assetIdentifiers: ["a"],
            suggestedKeepIdentifier: "a",
            estimatedSavingsBytes: 0
        )
        #expect(group.count == 1)
    }

    // MARK: - DuplicateGroup: duplicateIdentifiers

    @Test("duplicateIdentifiers excludes the suggested-keep identifier")
    func duplicateGroup_duplicateIdentifiers() {
        let group = DuplicateGroup(
            id: "g1",
            assetIdentifiers: ["a", "b", "c"],
            suggestedKeepIdentifier: "a",
            estimatedSavingsBytes: 0
        )
        let dupes = group.duplicateIdentifiers
        #expect(!dupes.contains("a"))
        #expect(dupes.contains("b"))
        #expect(dupes.contains("c"))
        #expect(dupes.count == 2)
    }

    @Test("duplicateIdentifiers is empty when only the kept asset exists")
    func duplicateGroup_duplicateIdentifiers_empty() {
        let group = DuplicateGroup(
            id: "g1",
            assetIdentifiers: ["a"],
            suggestedKeepIdentifier: "a",
            estimatedSavingsBytes: 0
        )
        #expect(group.duplicateIdentifiers.isEmpty)
    }

    // MARK: - PhotoAnalysisResult: duplicateCount

    @Test("duplicateCount sums extras across all groups")
    func photoResult_duplicateCount() {
        let groups = [
            DuplicateGroup(id: "1", assetIdentifiers: ["a", "b", "c"], suggestedKeepIdentifier: "a", estimatedSavingsBytes: 0),
            DuplicateGroup(id: "2", assetIdentifiers: ["x", "y"], suggestedKeepIdentifier: "x", estimatedSavingsBytes: 0),
        ]
        let result = PhotoAnalysisResult(
            totalPhotos: 100,
            duplicateGroups: groups,
            screenshotIdentifiers: [],
            largeVideoIdentifiers: [],
            blurryIdentifiers: []
        )
        // (3 - 1) + (2 - 1) = 3
        #expect(result.duplicateCount == 3)
    }

    @Test("duplicateCount is zero when there are no groups")
    func photoResult_duplicateCount_zero() {
        let result = PhotoAnalysisResult(
            totalPhotos: 50,
            duplicateGroups: [],
            screenshotIdentifiers: [],
            largeVideoIdentifiers: [],
            blurryIdentifiers: []
        )
        #expect(result.duplicateCount == 0)
    }

    // MARK: - PhotoAnalysisResult: estimatedDuplicateSavings

    @Test("estimatedDuplicateSavings sums savings across all groups")
    func photoResult_savings() {
        let groups = [
            DuplicateGroup(id: "1", assetIdentifiers: ["a", "b"], suggestedKeepIdentifier: "a", estimatedSavingsBytes: 2_000_000),
            DuplicateGroup(id: "2", assetIdentifiers: ["x", "y"], suggestedKeepIdentifier: "x", estimatedSavingsBytes: 3_000_000),
        ]
        let result = PhotoAnalysisResult(
            totalPhotos: 50,
            duplicateGroups: groups,
            screenshotIdentifiers: [],
            largeVideoIdentifiers: [],
            blurryIdentifiers: []
        )
        #expect(result.estimatedDuplicateSavings == 5_000_000)
    }

    @Test("estimatedDuplicateSavings is zero when no groups exist")
    func photoResult_savings_zero() {
        let result = PhotoAnalysisResult(
            totalPhotos: 0,
            duplicateGroups: [],
            screenshotIdentifiers: [],
            largeVideoIdentifiers: [],
            blurryIdentifiers: []
        )
        #expect(result.estimatedDuplicateSavings == 0)
    }

    // MARK: - PhotoAnalysisResult: count helpers

    @Test("screenshotCount, largeVideoCount, blurryCount return correct values")
    func photoResult_categoryCounts() {
        let result = PhotoAnalysisResult(
            totalPhotos: 200,
            duplicateGroups: [],
            screenshotIdentifiers: ["s1", "s2", "s3"],
            largeVideoIdentifiers: ["v1"],
            blurryIdentifiers: ["b1", "b2"]
        )
        #expect(result.screenshotCount == 3)
        #expect(result.largeVideoCount == 1)
        #expect(result.blurryCount == 2)
    }

    @Test("All counts are zero for an empty result")
    func photoResult_allZero() {
        let result = PhotoAnalysisResult(
            totalPhotos: 0,
            duplicateGroups: [],
            screenshotIdentifiers: [],
            largeVideoIdentifiers: [],
            blurryIdentifiers: []
        )
        #expect(result.duplicateCount == 0)
        #expect(result.estimatedDuplicateSavings == 0)
        #expect(result.screenshotCount == 0)
        #expect(result.largeVideoCount == 0)
        #expect(result.blurryCount == 0)
    }
}
