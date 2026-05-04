import Testing
@testable import PhoneCare

@Suite("BatteryMonitor")
@MainActor
struct BatteryMonitorTests {

    // MARK: - startMonitoring

    @Test("startMonitoring sets isMonitoring to true")
    func startMonitoring_setsTrue() {
        let monitor = BatteryMonitor()
        #expect(monitor.isMonitoring == false)
        monitor.startMonitoring()
        #expect(monitor.isMonitoring == true)
        monitor.stopMonitoring()
    }

    @Test("startMonitoring called twice does not crash and keeps isMonitoring true")
    func startMonitoring_idempotent() {
        let monitor = BatteryMonitor()
        monitor.startMonitoring()
        monitor.startMonitoring() // second call should be a no-op
        #expect(monitor.isMonitoring == true)
        monitor.stopMonitoring()
    }

    // MARK: - stopMonitoring

    @Test("stopMonitoring after startMonitoring sets isMonitoring to false")
    func stopMonitoring_afterStart_setsFalse() {
        let monitor = BatteryMonitor()
        monitor.startMonitoring()
        monitor.stopMonitoring()
        #expect(monitor.isMonitoring == false)
    }

    @Test("stopMonitoring without prior startMonitoring is a no-op")
    func stopMonitoring_withoutStart_noOp() {
        let monitor = BatteryMonitor()
        monitor.stopMonitoring()
        #expect(monitor.isMonitoring == false)
    }

    // MARK: - Battery Level (0.0–1.0 or -1.0 for simulator)

    @Test("Battery level after readCurrentState is within 0.0–1.0")
    func batteryLevel_afterReadCurrentState_inRange() {
        let monitor = BatteryMonitor()
        monitor.startMonitoring()
        monitor.readCurrentState()
        // BatteryMonitor clamps raw UIDevice.batteryLevel (-1 on simulator) with max(0, level)
        #expect(monitor.currentInfo.level >= 0.0)
        #expect(monitor.currentInfo.level <= 1.0)
        monitor.stopMonitoring()
    }

    @Test("Initial battery level is 0.0 before monitoring starts")
    func batteryLevel_initial_isZero() {
        let monitor = BatteryMonitor()
        #expect(monitor.currentInfo.level == 0.0)
    }

    @Test("levelPercentage derived from level is in 0–100")
    func levelPercentage_inRange() {
        let monitor = BatteryMonitor()
        monitor.startMonitoring()
        monitor.readCurrentState()
        #expect(monitor.currentInfo.levelPercentage >= 0)
        #expect(monitor.currentInfo.levelPercentage <= 100)
        monitor.stopMonitoring()
    }

    // MARK: - Thermal State

    @Test("Thermal state after readCurrentState is one of the four valid values")
    func thermalState_validValue() {
        let monitor = BatteryMonitor()
        monitor.startMonitoring()
        monitor.readCurrentState()
        let validStates: [BatteryInfo.ThermalState] = [.nominal, .fair, .serious, .critical]
        #expect(validStates.contains(monitor.currentInfo.thermalState))
        monitor.stopMonitoring()
    }

    @Test("Initial thermal state is nominal")
    func thermalState_initial_isNominal() {
        let monitor = BatteryMonitor()
        #expect(monitor.currentInfo.thermalState == .nominal)
    }

    @Test("ThermalState rawValues cover the full 0–3 range")
    func thermalState_rawValues() {
        #expect(BatteryInfo.ThermalState(rawValue: 0) == .nominal)
        #expect(BatteryInfo.ThermalState(rawValue: 1) == .fair)
        #expect(BatteryInfo.ThermalState(rawValue: 2) == .serious)
        #expect(BatteryInfo.ThermalState(rawValue: 3) == .critical)
        #expect(BatteryInfo.ThermalState(rawValue: 99) == nil)
    }

    // MARK: - Initial State

    @Test("Initial snapshots array is empty")
    func initialSnapshots_isEmpty() {
        let monitor = BatteryMonitor()
        #expect(monitor.snapshots.isEmpty)
    }

    @Test("Initial isLowPowerMode is false")
    func initialIsLowPowerMode_isFalse() {
        let monitor = BatteryMonitor()
        #expect(monitor.currentInfo.isLowPowerMode == false)
    }

    // MARK: - BatteryInfo helpers

    @Test("BatteryState displayNames are non-empty strings")
    func batteryState_displayNames_nonEmpty() {
        let states: [BatteryInfo.BatteryState] = [.unknown, .unplugged, .charging, .full]
        for state in states {
            #expect(!state.displayName.isEmpty, "displayName is empty for \(state)")
        }
    }

    @Test("BatteryState icons are non-empty SF Symbol names")
    func batteryState_icons_nonEmpty() {
        let states: [BatteryInfo.BatteryState] = [.unknown, .unplugged, .charging, .full]
        for state in states {
            #expect(!state.icon.isEmpty, "icon is empty for \(state)")
        }
    }

    @Test("ThermalState displayNames are non-empty strings")
    func thermalState_displayNames_nonEmpty() {
        let states: [BatteryInfo.ThermalState] = [.nominal, .fair, .serious, .critical]
        for state in states {
            #expect(!state.displayName.isEmpty, "displayName is empty for thermal \(state)")
        }
    }
}
