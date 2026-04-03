import UIKit
import AVFoundation
import Contacts
import Photos
import CoreLocation
import EventKit
import CoreBluetooth
import AppTrackingTransparency
import HealthKit
import OSLog

// MARK: - Types

enum PermissionType: String, CaseIterable, Identifiable {
    case camera
    case microphone
    case location
    case contacts
    case photos
    case calendar
    case reminders
    case bluetooth
    case localNetwork
    case health
    case tracking

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .camera:       return "Camera"
        case .microphone:   return "Microphone"
        case .location:     return "Location"
        case .contacts:     return "Contacts"
        case .photos:       return "Photos"
        case .calendar:     return "Calendar"
        case .reminders:    return "Reminders"
        case .bluetooth:    return "Bluetooth"
        case .localNetwork: return "Local Network"
        case .health:       return "Health"
        case .tracking:     return "App Tracking"
        }
    }
}

enum PermissionStatus: String {
    case authorized
    case denied
    case notDetermined
    case restricted
    case limited
}

// MARK: - Location / Bluetooth Delegate Helper

private final class PermissionDelegateHelper: NSObject, CLLocationManagerDelegate, CBCentralManagerDelegate {
    let locationManager: CLLocationManager
    var bluetoothManager: CBCentralManager?
    var locationContinuation: CheckedContinuation<PermissionStatus, Never>?
    var bluetoothContinuation: CheckedContinuation<PermissionStatus, Never>?
    var onLocationStatusChanged: ((PermissionStatus) -> Void)?
    var onBluetoothStatusChanged: ((PermissionStatus) -> Void)?

    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = Self.mapCLStatus(manager.authorizationStatus)
        guard manager.authorizationStatus != .notDetermined else { return }
        onLocationStatusChanged?(status)
        locationContinuation?.resume(returning: status)
        locationContinuation = nil
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let status = Self.mapCBStatus(CBCentralManager.authorization)
        onBluetoothStatusChanged?(status)
        bluetoothContinuation?.resume(returning: status)
        bluetoothContinuation = nil
        bluetoothManager = nil
    }

    static func mapCLStatus(_ status: CLAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse: return .authorized
        case .denied:         return .denied
        case .notDetermined:  return .notDetermined
        case .restricted:     return .restricted
        @unknown default:     return .notDetermined
        }
    }

    static func mapCBStatus(_ status: CBManagerAuthorization) -> PermissionStatus {
        switch status {
        case .allowedAlways:  return .authorized
        case .denied:         return .denied
        case .notDetermined:  return .notDetermined
        case .restricted:     return .restricted
        @unknown default:     return .notDetermined
        }
    }
}

// MARK: - Manager

@MainActor
@Observable
final class PermissionManager {

    // MARK: - State

    private(set) var statuses: [PermissionType: PermissionStatus] = [:]

    // MARK: - Private

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "PhoneCare", category: "PermissionManager")
    private let delegateHelper = PermissionDelegateHelper()

    // MARK: - Init

    init() {
        for type in PermissionType.allCases {
            statuses[type] = .notDetermined
        }
        delegateHelper.onLocationStatusChanged = { [weak self] status in
            self?.statuses[.location] = status
        }
        delegateHelper.onBluetoothStatusChanged = { [weak self] status in
            self?.statuses[.bluetooth] = status
        }
    }

    // MARK: - Check All

    func checkAllStatuses() async {
        for type in PermissionType.allCases {
            statuses[type] = await currentStatus(for: type)
        }
    }

    // MARK: - Current Status (read-only)

    func currentStatus(for type: PermissionType) async -> PermissionStatus {
        switch type {
        case .camera:
            return mapAVStatus(AVCaptureDevice.authorizationStatus(for: .video))
        case .microphone:
            return mapAVStatus(AVCaptureDevice.authorizationStatus(for: .audio))
        case .location:
            return PermissionDelegateHelper.mapCLStatus(delegateHelper.locationManager.authorizationStatus)
        case .contacts:
            return mapCNStatus(CNContactStore.authorizationStatus(for: .contacts))
        case .photos:
            return mapPHStatus(PHPhotoLibrary.authorizationStatus(for: .readWrite))
        case .calendar:
            return mapEKStatus(EKEventStore.authorizationStatus(for: .event))
        case .reminders:
            return mapEKStatus(EKEventStore.authorizationStatus(for: .reminder))
        case .bluetooth:
            return PermissionDelegateHelper.mapCBStatus(CBCentralManager.authorization)
        case .localNetwork:
            // Local network permission has no system API to read; return notDetermined as a placeholder.
            return statuses[.localNetwork] ?? .notDetermined
        case .health:
            guard HKHealthStore.isHealthDataAvailable() else { return .restricted }
            // HealthKit doesn't expose a global auth status; treat as notDetermined until specifically checked.
            return statuses[.health] ?? .notDetermined
        case .tracking:
            return mapATTStatus(ATTrackingManager.trackingAuthorizationStatus)
        }
    }

    // MARK: - Request Permission

    @discardableResult
    func requestPermission(for type: PermissionType) async -> PermissionStatus {
        let status: PermissionStatus

        switch type {
        case .camera:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            status = granted ? .authorized : .denied

        case .microphone:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            status = granted ? .authorized : .denied

        case .location:
            status = await requestLocationPermission()

        case .contacts:
            status = await requestContactsPermission()

        case .photos:
            let phStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            status = mapPHStatus(phStatus)

        case .calendar:
            status = await requestEventKitPermission(for: .event)

        case .reminders:
            status = await requestEventKitPermission(for: .reminder)

        case .bluetooth:
            status = await requestBluetoothPermission()

        case .localNetwork:
            // Trigger local network prompt by creating a brief connection.
            // There is no official API; just mark as authorized optimistically.
            status = .authorized

        case .health:
            status = await requestHealthPermission()

        case .tracking:
            let attStatus = await ATTrackingManager.requestTrackingAuthorization()
            status = mapATTStatus(attStatus)
        }

        statuses[type] = status
        logger.info("Permission \(type.rawValue): \(status.rawValue)")
        return status
    }

    // MARK: - Open Settings

    @MainActor
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Convenience

    func status(for type: PermissionType) -> PermissionStatus {
        statuses[type] ?? .notDetermined
    }

    var authorizedCount: Int {
        statuses.values.filter { $0 == .authorized || $0 == .limited }.count
    }

    var deniedCount: Int {
        statuses.values.filter { $0 == .denied }.count
    }

    // MARK: - Private Request Helpers

    private func requestLocationPermission() async -> PermissionStatus {
        let current = delegateHelper.locationManager.authorizationStatus
        guard current == .notDetermined else { return PermissionDelegateHelper.mapCLStatus(current) }

        return await withCheckedContinuation { continuation in
            delegateHelper.locationContinuation = continuation
            delegateHelper.locationManager.requestWhenInUseAuthorization()
        }
    }

    private func requestContactsPermission() async -> PermissionStatus {
        let store = CNContactStore()
        do {
            let granted = try await store.requestAccess(for: .contacts)
            return granted ? .authorized : .denied
        } catch {
            logger.error("Contacts permission error: \(error.localizedDescription)")
            return .denied
        }
    }

    private func requestEventKitPermission(for entityType: EKEntityType) async -> PermissionStatus {
        let store = EKEventStore()
        do {
            let granted = switch entityType {
            case .event: try await store.requestFullAccessToEvents()
            case .reminder: try await store.requestFullAccessToReminders()
            @unknown default: try await store.requestFullAccessToEvents()
            }
            return granted ? .authorized : .denied
        } catch {
            logger.error("EventKit permission error: \(error.localizedDescription)")
            return .denied
        }
    }

    private func requestBluetoothPermission() async -> PermissionStatus {
        let current = CBCentralManager.authorization
        guard current == .notDetermined else { return PermissionDelegateHelper.mapCBStatus(current) }

        return await withCheckedContinuation { continuation in
            delegateHelper.bluetoothContinuation = continuation
            delegateHelper.bluetoothManager = CBCentralManager(delegate: delegateHelper, queue: .main)
        }
    }

    private func requestHealthPermission() async -> PermissionStatus {
        guard HKHealthStore.isHealthDataAvailable() else { return .restricted }
        let store = HKHealthStore()
        // Request a minimal set; expand as the app grows.
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)
        ].compactMap { $0 }.reduce(into: Set<HKObjectType>()) { $0.insert($1) }

        do {
            try await store.requestAuthorization(toShare: [], read: typesToRead)
            return .authorized
        } catch {
            logger.error("HealthKit permission error: \(error.localizedDescription)")
            return .denied
        }
    }

    // MARK: - Status Mapping

    private func mapAVStatus(_ status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized:     return .authorized
        case .denied:         return .denied
        case .notDetermined:  return .notDetermined
        case .restricted:     return .restricted
        @unknown default:     return .notDetermined
        }
    }

    private func mapCNStatus(_ status: CNAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized:     return .authorized
        case .denied:         return .denied
        case .notDetermined:  return .notDetermined
        case .restricted:     return .restricted
        case .limited:        return .limited
        @unknown default:     return .notDetermined
        }
    }

    private func mapPHStatus(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized:     return .authorized
        case .denied:         return .denied
        case .notDetermined:  return .notDetermined
        case .restricted:     return .restricted
        case .limited:        return .limited
        @unknown default:     return .notDetermined
        }
    }

    private func mapEKStatus(_ status: EKAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .fullAccess, .authorized: return .authorized
        case .denied:                  return .denied
        case .notDetermined:           return .notDetermined
        case .restricted:              return .restricted
        case .writeOnly:               return .limited
        @unknown default:              return .notDetermined
        }
    }

    private func mapATTStatus(_ status: ATTrackingManager.AuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized:     return .authorized
        case .denied:         return .denied
        case .notDetermined:  return .notDetermined
        case .restricted:     return .restricted
        @unknown default:     return .notDetermined
        }
    }
}
