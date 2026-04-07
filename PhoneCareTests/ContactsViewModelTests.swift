import Testing
import Foundation
@testable import PhoneCare

@Suite("ContactsViewModel")
@MainActor
struct ContactsViewModelTests {

    // MARK: - Initial state

    @Test("isLoading starts false")
    func initialState_notLoading() {
        let vm = ContactsViewModel()
        #expect(vm.isLoading == false)
    }

    @Test("isScanning starts false")
    func initialState_notScanning() {
        let vm = ContactsViewModel()
        #expect(vm.isScanning == false)
    }

    @Test("scanComplete starts false")
    func initialState_scanNotComplete() {
        let vm = ContactsViewModel()
        #expect(vm.scanComplete == false)
    }

    @Test("duplicateGroups starts empty")
    func initialState_noDuplicateGroups() {
        let vm = ContactsViewModel()
        #expect(vm.duplicateGroups.isEmpty)
    }

    @Test("isMerging starts false")
    func initialState_notMerging() {
        let vm = ContactsViewModel()
        #expect(vm.isMerging == false)
    }

    @Test("showUndoToast starts false")
    func initialState_noUndoToast() {
        let vm = ContactsViewModel()
        #expect(vm.showUndoToast == false)
    }

    @Test("lastMergedCount starts at zero")
    func initialState_lastMergedCount_zero() {
        let vm = ContactsViewModel()
        #expect(vm.lastMergedCount == 0)
    }

    @Test("alertInfo starts nil")
    func initialState_noAlert() {
        let vm = ContactsViewModel()
        #expect(vm.alertInfo == nil)
    }

    @Test("totalContacts starts at zero")
    func initialState_totalContacts_zero() {
        let vm = ContactsViewModel()
        #expect(vm.totalContacts == 0)
    }

    @Test("duplicateCount starts at zero")
    func initialState_duplicateCount_zero() {
        let vm = ContactsViewModel()
        #expect(vm.duplicateCount == 0)
    }

    // MARK: - Scan without Contacts authorisation

    @Test("startScan without authorisation clears results and shows an alert")
    func startScan_unauthorized_showsAlert() {
        // Contacts authorisation is .notDetermined / .denied in the test
        // environment, so calling startScan should hit the guard branch,
        // clear results, and surface an alert.
        let vm = ContactsViewModel()
        let dataManager = DataManager(inMemory: true)

        vm.startScan(dataManager: dataManager)

        #expect(vm.scanComplete == false)
        #expect(vm.duplicateGroups.isEmpty)
        #expect(vm.duplicateCount == 0)
        #expect(vm.alertInfo != nil)
        #expect(vm.alertInfo?.title == "Contacts Access Needed")
    }

    // MARK: - Load from DataManager

    @Test("load from empty DataManager leaves counts at zero")
    func load_emptyDataManager_zeroCounts() {
        let vm = ContactsViewModel()
        let dataManager = DataManager(inMemory: true)

        vm.load(dataManager: dataManager)

        #expect(vm.totalContacts == 0)
        #expect(vm.duplicateCount == 0)
        #expect(vm.scanComplete == false)
    }

    // MARK: - DuplicateContactGroup model

    @Test("DuplicateContactGroup id is preserved")
    func duplicateContactGroup_id() {
        let group = DuplicateContactGroup(
            id: "group-1",
            name: "Alice Smith",
            suggestedPrimaryID: "id1",
            contactIDs: ["id1", "id2"],
            fields: []
        )
        #expect(group.id == "group-1")
    }

    @Test("DuplicateContactGroup stores contactIDs correctly")
    func duplicateContactGroup_contactIDs() {
        let group = DuplicateContactGroup(
            id: "group-2",
            name: "Bob Jones",
            suggestedPrimaryID: "bob1",
            contactIDs: ["bob1", "bob2", "bob3"],
            fields: []
        )
        #expect(group.contactIDs.count == 3)
        #expect(group.suggestedPrimaryID == "bob1")
    }

    // MARK: - ContactField model

    @Test("ContactField id is preserved")
    func contactField_id() {
        let field = ContactField(
            id: "phone",
            label: "Phone",
            values: ["555-1234", "555-5678"],
            selectedIndex: 0
        )
        #expect(field.id == "phone")
    }

    @Test("ContactField selectedIndex can be mutated")
    func contactField_mutableSelectedIndex() {
        var field = ContactField(
            id: "email",
            label: "Email",
            values: ["a@test.com", "b@test.com"],
            selectedIndex: 0
        )
        field.selectedIndex = 1
        #expect(field.selectedIndex == 1)
    }

    // MARK: - ContactsAlertInfo model

    @Test("ContactsAlertInfo stores title and message")
    func contactsAlertInfo_fields() {
        let info = ContactsAlertInfo(title: "Error", message: "Something went wrong.")
        #expect(info.title == "Error")
        #expect(info.message == "Something went wrong.")
    }

    @Test("ContactsAlertInfo generates a unique id each time")
    func contactsAlertInfo_uniqueID() {
        let a = ContactsAlertInfo(title: "T", message: "M")
        let b = ContactsAlertInfo(title: "T", message: "M")
        #expect(a.id != b.id)
    }
}
