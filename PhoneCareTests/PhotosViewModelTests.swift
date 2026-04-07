import Testing
import Foundation
@testable import PhoneCare

@Suite("PhotosViewModel")
@MainActor
struct PhotosViewModelTests {

    // MARK: - Initial state

    @Test("isScanning starts false")
    func initialState_notScanning() {
        let vm = PhotosViewModel()
        #expect(vm.isScanning == false)
    }

    @Test("scanComplete starts false")
    func initialState_scanNotComplete() {
        let vm = PhotosViewModel()
        #expect(vm.scanComplete == false)
    }

    @Test("selectedCategory defaults to duplicates")
    func initialState_defaultCategory() {
        let vm = PhotosViewModel()
        #expect(vm.selectedCategory == .duplicates)
    }

    @Test("selectedPhotoIDs starts empty")
    func initialState_noSelection() {
        let vm = PhotosViewModel()
        #expect(vm.selectedPhotoIDs.isEmpty)
    }

    @Test("hasResults is false when all categories are empty")
    func hasResults_falseWhenEmpty() {
        let vm = PhotosViewModel()
        #expect(vm.hasResults == false)
    }

    // MARK: - Selection

    @Test("toggleSelection adds an ID that was not selected")
    func toggleSelection_adds() {
        let vm = PhotosViewModel()
        vm.toggleSelection("photo1")
        #expect(vm.selectedPhotoIDs.contains("photo1"))
    }

    @Test("toggleSelection removes an ID that was already selected")
    func toggleSelection_removes() {
        let vm = PhotosViewModel()
        vm.toggleSelection("photo1")
        vm.toggleSelection("photo1")
        #expect(!vm.selectedPhotoIDs.contains("photo1"))
    }

    @Test("selectAll adds all provided IDs to the selection")
    func selectAll_addsAllIDs() {
        let vm = PhotosViewModel()
        vm.selectAll(in: ["a", "b", "c"])
        #expect(vm.selectedPhotoIDs == ["a", "b", "c"])
    }

    @Test("deselectAll clears the selection")
    func deselectAll_clearsSelection() {
        let vm = PhotosViewModel()
        vm.selectAll(in: ["a", "b", "c"])
        vm.deselectAll()
        #expect(vm.selectedPhotoIDs.isEmpty)
    }

    @Test("selectedCount reflects the number of selected IDs")
    func selectedCount() {
        let vm = PhotosViewModel()
        vm.selectAll(in: ["a", "b", "c"])
        #expect(vm.selectedCount == 3)
    }

    // MARK: - Premium gating

    @Test("isGroupAccessible returns true for any index when isPremium")
    func isGroupAccessible_premium() {
        let vm = PhotosViewModel()
        for index in 0..<10 {
            #expect(vm.isGroupAccessible(index: index, isPremium: true))
        }
    }

    @Test("isGroupAccessible returns false for index at freeGroupLimit when not premium")
    func isGroupAccessible_free_atLimit() {
        let vm = PhotosViewModel()
        #expect(vm.isGroupAccessible(index: vm.freeGroupLimit, isPremium: false) == false)
    }

    @Test("isGroupAccessible returns true for index below freeGroupLimit when not premium")
    func isGroupAccessible_free_belowLimit() {
        let vm = PhotosViewModel()
        for index in 0..<vm.freeGroupLimit {
            #expect(vm.isGroupAccessible(index: index, isPremium: false))
        }
    }

    @Test("visibleDuplicateGroups returns empty for both premium and free on a fresh instance")
    func visibleDuplicateGroups_emptyBaseline() {
        let vm = PhotosViewModel()
        #expect(vm.visibleDuplicateGroups(isPremium: true).isEmpty)
        #expect(vm.visibleDuplicateGroups(isPremium: false).isEmpty)
    }

    // MARK: - Category description

    @Test("currentCategoryDescription returns no-duplicates message when empty")
    func categoryDescription_duplicates_empty() {
        let vm = PhotosViewModel()
        vm.selectedCategory = .duplicates
        #expect(vm.currentCategoryDescription == "No duplicates found")
    }

    @Test("currentCategoryDescription returns no-screenshots message when empty")
    func categoryDescription_screenshots_empty() {
        let vm = PhotosViewModel()
        vm.selectedCategory = .screenshots
        #expect(vm.currentCategoryDescription == "No screenshots found")
    }

    @Test("currentCategoryDescription returns no-blurry message when empty")
    func categoryDescription_blurry_empty() {
        let vm = PhotosViewModel()
        vm.selectedCategory = .blurry
        #expect(vm.currentCategoryDescription == "No blurry photos found")
    }

    @Test("currentCategoryDescription returns no-large-videos message when empty")
    func categoryDescription_largeVideos_empty() {
        let vm = PhotosViewModel()
        vm.selectedCategory = .largeVideos
        #expect(vm.currentCategoryDescription == "No large videos found")
    }

    // MARK: - Batch delete

    @Test("prepareBatchDelete does nothing when selection is empty")
    func prepareBatchDelete_noOp() {
        let vm = PhotosViewModel()
        vm.prepareBatchDelete()
        #expect(vm.showBatchDeleteSheet == false)
    }

    @Test("prepareBatchDelete shows sheet when IDs are selected")
    func prepareBatchDelete_showsSheet() {
        let vm = PhotosViewModel()
        vm.toggleSelection("photo1")
        vm.prepareBatchDelete()
        #expect(vm.showBatchDeleteSheet == true)
    }

    @Test("confirmBatchDelete records the deleted count and triggers undo toast")
    func confirmBatchDelete_counts() {
        let vm = PhotosViewModel()
        vm.selectAll(in: ["a", "b", "c"])
        vm.prepareBatchDelete()
        vm.confirmBatchDelete()
        #expect(vm.lastDeletedCount == 3)
        #expect(vm.showUndoToast == true)
        #expect(vm.showBatchDeleteSheet == false)
        #expect(vm.selectedPhotoIDs.isEmpty)
    }

    @Test("undoDelete clears the undo toast")
    func undoDelete_clearsToast() {
        let vm = PhotosViewModel()
        vm.selectAll(in: ["a"])
        vm.prepareBatchDelete()
        vm.confirmBatchDelete()
        vm.undoDelete()
        #expect(vm.showUndoToast == false)
    }
}
