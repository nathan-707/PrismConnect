//
//  sessionManager.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 2/25/25.
//

import CoreBluetooth
import Foundation
import SwiftUI

#if os(iOS)
    import AccessorySetupKit
#endif

let currentVersion = 2  // use this to force clock to update if app needs to.

enum Views {
    case connectedMainMenu, connectedLightEffects
}

class ClockSessionManager: NSObject, ObservableObject {
    var isShowingWeatherSpace = true
    @Published var presentManagerDeviceView = false
    @Published var lastKnownLat: Double = 0
    @Published var lastKnownLong: Double = 0
    @Published var failedGetHomeWeatherAttempts = 0
    @Published var reportWeatherError = false
    @Published var showConnectToPrismboxButton = false

    private var currentSystemTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"  // This ensures a space before AM/PM
        return formatter.string(from: Date())
    }

    @Published var showFunfact: Bool = true
    @Published var showTemperature: Bool = true
    @Published var soundOn: Bool = true
    @Published var rainSnowGain: Double = 10

    @Published var imperial = true {
        didSet {
            updateDisplayedTemperatureFromRaw()
        }
    }
    @Published var initHomeWeather = false
    @Published var worldTourIsOn: Bool = false
    @Published var userColor: Color = .green
    @Published var locationDenied = false
    @Published var weatherRequestIsPending = false

    func getCurrentTemp() -> String {
        if imperial {
            return "\(clock_temperature) °F"
        } else {
            return "\(clock_temperature) °C"
        }
    }

    private func updateDisplayedTemperatureFromRaw() {
        if imperial {
            clock_temperature = rawTemperatureFahrenheit
        } else {
            let celsius = (Double(rawTemperatureFahrenheit) - 32) * 5 / 9
            clock_temperature = Int(round(celsius))
        }
    }

    var failedHome = true
    var failedTeleport = true

    func getWeather(mode: Modes, city: City) {
        if virtualClock == nil {
            virtualClock = VirtualColorClock()
            virtualClock?.sessionManager = self
        }

        Task { @MainActor in
            let success = await virtualClock?.getWeather(mode: mode, city: city)

            if let success = success {
                if success {
                    switch mode {
                    case .home:
                        failedHome = false
                    default:
                        failedTeleport = false
                    }
                } else {
                    failedHome = true
                    failedTeleport = true
                    if mode == .teleportMode {
                        standalonemode_Mode = .home
                        print("teleport failed. switched back to home mode.")
                    }
                }
            }
            syncVirtualClockToWeather()
        }
    }

    private func syncVirtualClockToWeather() {
        if let virtualClock {
            Task { @MainActor in
                self.clock_weather = virtualClock.currentWeather.weatherLight
                self.rawTemperatureFahrenheit = Int(
                    virtualClock.currentWeather.temp_main
                )
                self.updateDisplayedTemperatureFromRaw()
            }
        }
    }

    var reportConnectionTask: Task<Void, Never>?

    func waitToTryToConnectAndReport() {
        reportConnectionTask = Task<Void, Never> { @MainActor in
            if debug.skipClockSearch { return }
            searchingForClock = true

            if manager == nil {
                manager = CBCentralManager(delegate: self, queue: nil)
            }

            try? await Task.sleep(for: .seconds(5))

            if peripheralConnected {
                isStandaloneMode = false
                tryToTurnOnStandAloneMode = true
            } else {
                isStandaloneMode = true
                tryToTurnOnStandAloneMode = false
            }

            searchingForClock = false

            Task<Void, Never> { @MainActor in
                reportConnection = true
                try? await Task.sleep(for: .seconds(2))
                reportConnection = false
            }
        }
    }
    
    func disconnectAndRetry(){
        print("Cannot write: Peripheral or characteristic unavailable, or not writable. disconnecting and reconneting to try to fix.")
        return
    }

    // standalone.
    @Published var timeScale: Double = 1
    @Published var tempScale: Double = 1

    @Published var isStandaloneMode: Bool = true
    @Published var standalonemode_Mode: Modes = .home
    @Published var standalone_worldTourInterval_Mins: Int = 15  // default tour time in vision app
    @Published var showBattery: Bool = false

    @Published var presentSettings: Bool = false
    @Published var presentSelectLocationView = false
    @Published var searchingForClock = false
    @Published var reportConnection = false
    @Published var tryToTurnOnStandAloneMode: Bool = false

    // end of standalone vars.
    var virtualClock: VirtualColorClock?
    @Published var showingFullTrackingSpace = false
    @Published var cityIsSelected = true

    // MARK: - clock info
    @Published var wholeRoom = false
    @Published var clock_time_hour: Int = 0
    @Published var clock_time_min: Int = 0
    @Published var clock_weekDay: Int = 0
    @Published var clock_DOM: Int = 0
    @Published var clock_month: Int = 0
    @Published var cutOff: Int = 0
    @Published var isDay: Bool = false
    @Published var isAm: Bool = false
    @Published var hasConnected = false

    // MARK: - Settings
    @Published var version: Int = 0
    @Published var currentMode: Modes = .sleepMode
    @Published var currentLightEffect: LightEffects = .custom_m
    @Published var currentLayout = 1
    @Published var pending: Bool = false
    @Published var masterEffect: MasterEffect = .showW
    @Published var ignoreAlerts: Bool = false
    @Published var disableAlertFlashing: Bool = false
    @Published var autoBrightnessOn: Bool = false
    @Published var tourInterval: Int = 15
    @Published var onTime: Int = 1
    @Published var offTime: Int = 1
    @Published var autoOff: Bool = false
    @Published var selectedTeleportCity: City = worldTourCity
    @Published var CurrentTeleportation: City = worldTourCity
    var lastTourCity: City = worldTourCity
    @Published var getTimeInTel: Bool = false
    @Published var semiAutoTurnOff: Bool = false
    @Published var brightness: Float = 1
    @Published var sleepTimer: Int = 0
    @Published var SpecFS: Float = 3
    @Published var HeadFS: Float = 3
    @Published var SCFS: Float = 3
    @Published var FireFS: Float = 3
    @Published var smallMode: Int = 0
    @Published var largeMode: Int = 0
    @Published var selectedPark: ThemePark = AllParks[0]
    @Published var muted: Int = 0

    // Effect speed settings.
    @Published var customRed: Int = 255
    @Published var customGreen: Int = 255
    @Published var customBlue: Int = 255
    @Published var tempRed: Int = 0
    @Published var tempGreen: Int = 0
    @Published var tempBlue: Int = 0
    @Published var CurrentParkClockIsIn: ThemePark = AllParks[0]
    @Published var sleepTimerOn: Bool = false
    @Published var tempClockColor: CGColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0)
    @Published var customColor: CGColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0)
    @Published var clock_weather: WeatherLight = .UNKNOWN
    @Published var clock_temperature: Int = 0
    private var rawTemperatureFahrenheit: Int = 0

    // future proofing
    @Published var somethingICanUse1: Int = 0
    @Published var somethingICanUse2: Int = 0
    @Published var somethingICanUse3: Int = 0

    @Published var clockTime: String = ""

    func updateTime() {
        if self.peripheralConnected == false || self.isStandaloneMode == true {
            clockTime = self.currentSystemTime
            return
        }

        if clock_time_min >= 10 {
            clockTime = "\(clock_time_hour):\(clock_time_min)"
        } else {
            clockTime = "\(clock_time_hour) \(":") \("0")\(clock_time_min)"
        }
    }

    func syncState(update: VisionInfo) {
        if debug.printStateUpdates {
            print("vision update")
            print(update)
        }

        isAm = update.am
        isDay = update.isDay
        CurrentTeleportation = returnCityFromID(ID: update.city)
        CurrentParkClockIsIn = matchParkIDtoPark(ID: update.park)
        currentMode = Modes(rawValue: update.mode) ?? .home
        clock_time_min = update.timeMin
        clock_time_hour = update.timeHour
        clock_weekDay = update.weekDay
        clock_DOM = update.DOM
        clock_month = update.month
        clock_weather = WeatherLight.from(update.weather) ?? .CLEAR_DAY
        rawTemperatureFahrenheit = update.temp
        updateDisplayedTemperatureFromRaw()
        pending = (update.visionP != 0)
        tempClockColor = CGColor(
            red: CGFloat(update.tempR) / 255,
            green: CGFloat(update.tempG) / 255,
            blue: CGFloat(update.tempB) / 255,
            alpha: 1
        )
    }

    func syncState(update: ClockSettings) {
        if debug.printStateUpdates {
            print("setting update")
            print(update)
        }

        somethingICanUse1 = update.e1
        somethingICanUse2 = update.e2
        somethingICanUse3 = update.e3
        currentMode = Modes(rawValue: update.mode) ?? .home
        clock_weather = WeatherLight.from(update.weather) ?? .CLEAR_DAY
        rawTemperatureFahrenheit = update.temp
        updateDisplayedTemperatureFromRaw()
        clock_time_hour = update.hour
        clock_time_min = update.min
        isAm = update.am
        isDay = update.isDay
        pending = (update.pending != 0)
        ignoreAlerts = (update.ignoreAlert != 0)
        disableAlertFlashing = (update.disAB != 0)
        smallMode = update.smallMode
        largeMode = update.largeMode
        getTimeInTel = (update.getTimeInTel != 0)
        version = update.ver
        currentLayout = update.layout
        muted = update.muted
        masterEffect = MasterEffect(rawValue: update.masterEffect) ?? .showW
        currentLightEffect = LightEffects(rawValue: update.effect) ?? .custom_m
        SpecFS = update.SpecFS
        HeadFS = update.HeadFS
        SCFS = update.SCFS
        FireFS = update.FireFS
        customRed = update.cR
        customGreen = update.cG
        customBlue = update.cB
        customColor = CGColor(
            red: CGFloat(update.cR) / 255,
            green: CGFloat(update.cG) / 255,
            blue: CGFloat(update.cB) / 255,
            alpha: 1
        )

        if update.pending.true {
            tempClockColor = CGColor(
                red: CGFloat(update.tempR) / 255,
                green: CGFloat(update.tempG) / 255,
                blue: CGFloat(update.tempB) / 255,
                alpha: 0.0
            )
        } else {
            tempClockColor = CGColor(
                red: CGFloat(update.tempR) / 255,
                green: CGFloat(update.tempG) / 255,
                blue: CGFloat(update.tempB) / 255,
                alpha: 1
            )
        }

        CurrentParkClockIsIn = matchParkIDtoPark(ID: update.park)
        tourInterval = update.telIn
        CurrentTeleportation = returnCityFromID(ID: update.city)
        onTime = update.onT
        offTime = update.offT
        autoOff = (update.autoOff != 0)
        semiAutoTurnOff = (update.semi != 0)
        brightness = update.br
        autoBrightnessOn = (update.aBr != 0)
        sleepTimer = update.sTi
        sleepTimerOn = (update.sTon != 0)

        if pending == false {
            pendingMode = Modes(rawValue: update.mode) ?? .home
        }

        if update.ver < currentVersion {
            updateLatest()
        }
    }

    @Published var appView: Views = .connectedMainMenu
    @Published var prismDevice: PrismDevice?
    @Published var peripheralConnected = false
    @Published var pickerDismissed = true
    @Published var authenticated = true
    @Published var pendingMode: Modes = .home

    private var manager: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var clockSettingsCharacteristic: CBCharacteristic?
    private var vCharacteristic: CBCharacteristic?

    private static let vCharacteristic_UUID = "beb4538e-36e1-4688-b7f5-ea07361b26a8"
    private static let clockUpdateCharacteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8"
    private static let SERVICE_UUID = "E56A082E-C49B-47CA-A2AB-389127B8ABE3"

    #if os(iOS)
        var currentDice: ASAccessory?
        var session = ASAccessorySession()

        // MARK: - Accessory Picker Items
        private static let PencilHolderPickerItem: ASPickerDisplayItem = {
            let descriptor = ASDiscoveryDescriptor()
            descriptor.bluetoothServiceUUID = PrismDevice.pencilHolder.serviceUUID

            return ASPickerDisplayItem(
                name: PrismDevice.pencilHolder.displayName,
                productImage: UIImage(named: PrismDevice.pencilHolder.productImageName)!,
                descriptor: descriptor
            )
        }()

        private static let ClockPickerItem: ASPickerDisplayItem = {
            let descriptor = ASDiscoveryDescriptor()
            descriptor.bluetoothServiceUUID = PrismDevice.clock.serviceUUID
            return ASPickerDisplayItem(
                name: PrismDevice.clock.displayName,
                productImage: UIImage(named: PrismDevice.clock.productImageName)!,
                descriptor: descriptor
            )
        }()
    #endif

    // MARK: - Initialization
    override init() {
        super.init()
        #if os(iOS)
            self.session.activate(
                on: DispatchQueue.main,
                eventHandler: handleSessionEvent(event:)
            )
        #endif
    }
    
    #if os(iOS)
        // MARK: - Persistence & Registry Helpers
        private func persistLastDevice(accessory: ASAccessory) {
            if let uuid = accessory.bluetoothIdentifier {
                UserDefaults.standard.set(uuid.uuidString, forKey: "lastConnectedDeviceUUID")
            }
        }
        
        private func getDeviceType(for uuid: UUID?) -> PrismDevice? {
            guard let uuidString = uuid?.uuidString else { return nil }
            let registry = UserDefaults.standard.dictionary(forKey: "PrismDeviceRegistry") as? [String: String] ?? [:]
            
            if registry[uuidString] == "clock" { return .clock }
            if registry[uuidString] == "pencilHolder" { return .pencilHolder }
            return nil
        }

        private func registerDeviceType(for uuid: UUID?, type: PrismDevice) {
            guard let uuidString = uuid?.uuidString else { return }
            var registry = UserDefaults.standard.dictionary(forKey: "PrismDeviceRegistry") as? [String: String] ?? [:]
            
            if type == .clock { registry[uuidString] = "clock" }
            else if type == .pencilHolder { registry[uuidString] = "pencilHolder" }
            
            UserDefaults.standard.set(registry, forKey: "PrismDeviceRegistry")
        }
    
        // MARK: - Accessory Switching
        func switchToKnownAccessory(accessory: ASAccessory) {
            print("Switching to \(accessory.displayName)...")

                let targetDevice = getDeviceType(for: accessory.bluetoothIdentifier)
                
                // FIX: Cancel any existing or pending connections before overwriting
                if self.peripheral != nil {
                    disconnect()
                }
                
                if authenticated {
                    currentDice = accessory
                    persistLastDevice(accessory: accessory)
                }
            
            if let targetDevice = targetDevice {
                prismDevice = targetDevice
            } else {
                print("Device type unknown (first connect). Type will resolve automatically upon connection.")
            }

            if manager == nil {
                print("Initializing Central Manager. Waiting for power up...")
                manager = CBCentralManager(delegate: self, queue: nil)
            } else if manager?.state == .poweredOn {
                if let peripheralUUID = accessory.bluetoothIdentifier {
                    let retrieved = manager?.retrievePeripherals(withIdentifiers: [peripheralUUID]) ?? []
                    if let newPeripheral = retrieved.first {
                        print("Found peripheral: \(newPeripheral). Connecting...")
                        peripheral = newPeripheral
                        peripheral?.delegate = self
                        connect()
                    } else {
                        print("Failed to retrieve peripheral for accessory: \(accessory.displayName). It might be out of range.")
                    }
                }
            } else {
                print("Bluetooth is not ready yet. Connection will happen automatically when powered on.")
            }
        }
    
        func manageDevices() {
            print("manage")
            let accessories = session.accessories
            guard accessories.count > 1 else {
                print("Not enough devices to switch between.")
                return
            }

            var targetDevice: PrismDevice?
            var targetAccessory: ASAccessory?

            if prismDevice == .clock {
                targetDevice = .pencilHolder
                targetAccessory = accessories.first { getDeviceType(for: $0.bluetoothIdentifier) == .pencilHolder }
            } else if prismDevice == .pencilHolder {
                targetDevice = .clock
                targetAccessory = accessories.first { getDeviceType(for: $0.bluetoothIdentifier) == .clock }
            }
            
            // Fallback for unregistered or new devices
            if targetAccessory == nil {
                targetAccessory = accessories.first { $0.bluetoothIdentifier != currentDice?.bluetoothIdentifier }
                targetDevice = getDeviceType(for: targetAccessory?.bluetoothIdentifier)
            }

            guard let finalAccessory = targetAccessory else { return }

            if peripheralConnected { disconnect() }

            currentDice = finalAccessory
            persistLastDevice(accessory: finalAccessory)
            if let knownDevice = targetDevice { prismDevice = knownDevice }

            if manager == nil {
                print("Initializing Central Manager. Waiting for power up...")
                manager = CBCentralManager(delegate: self, queue: nil)
            } else if manager?.state == .poweredOn {
                if let peripheralUUID = finalAccessory.bluetoothIdentifier {
                    let retrieved = manager?.retrievePeripherals(withIdentifiers: [peripheralUUID]) ?? []
                    if let newPeripheral = retrieved.first {
                        peripheral = newPeripheral
                        peripheral?.delegate = self
                        connect()
                    } else {
                        print("Failed to retrieve peripheral for accessory: \(finalAccessory.displayName)")
                    }
                }
            } else {
                print("Bluetooth is not ready yet. Connection will happen automatically when powered on.")
            }
        }
    
        func presentPicker() {
            Self.ClockPickerItem.setupOptions = .confirmAuthorization
            Self.PencilHolderPickerItem.setupOptions = .confirmAuthorization

            session.showPicker(for: [Self.ClockPickerItem, Self.PencilHolderPickerItem]) { error in
                if let error = error {
                    print("Failed to show picker due to: \(error.localizedDescription)")
                }
            }
        }

        func removePrismBox() {
            guard let currentDice = currentDice else { return }
            let deviceUUIDToRemove = currentDice.bluetoothIdentifier?.uuidString

            if peripheralConnected {
                disconnect()
            }

            session.removeAccessory(currentDice) { _ in
                if let savedString = UserDefaults.standard.string(forKey: "lastConnectedDeviceUUID"),
                   let currentUUIDString = deviceUUIDToRemove,
                   savedString == currentUUIDString {
                    UserDefaults.standard.removeObject(forKey: "lastConnectedDeviceUUID")
                }
                
                // Clear from registry
                if let uuidStr = deviceUUIDToRemove {
                    var registry = UserDefaults.standard.dictionary(forKey: "PrismDeviceRegistry") as? [String: String] ?? [:]
                    registry.removeValue(forKey: uuidStr)
                    UserDefaults.standard.set(registry, forKey: "PrismDeviceRegistry")
                }

                self.prismDevice = nil
                self.currentDice = nil
                self.manager = nil
            }
        }

        private func savePrismBox(prismBox: ASAccessory) {
            currentDice = prismBox
            persistLastDevice(accessory: prismBox)
            
            if let knownType = getDeviceType(for: prismBox.bluetoothIdentifier) {
                prismDevice = knownType
            } else {
                print("Device type unknown (first connect). Type will resolve automatically upon connection.")
            }

            if manager == nil {
                manager = CBCentralManager(delegate: self, queue: nil)
            }
        }

    private func handleSessionEvent(event: ASAccessoryEvent) {
        switch event.eventType {
        case .pickerSetupPairing:
            print("Pairing in progress...")
            authenticated = false
            
        case .accessoryAdded, .accessoryChanged:
            guard let prismBox = event.accessory else { return }
            
            
            
            
            
            
            // FIX: Stop the boot-spam loop!
            // We only want to auto-switch if we are actively pairing a new device,
            // or if we have absolutely nothing set.
            if authenticated == false || currentDice == nil {
                switchToKnownAccessory(accessory: prismBox)
                savePrismBox(prismBox: prismBox)
            } else {
                // Keep the reference fresh if it's the active device, but don't hijack the connection
                if currentDice?.bluetoothIdentifier == prismBox.bluetoothIdentifier {
                    currentDice = prismBox
                }
                print("Background accessory load ignored to preserve selected connection.")
            }
            
        case .activated:
            let accessories = session.accessories
            guard !accessories.isEmpty else { return }

            if let savedString = UserDefaults.standard.string(forKey: "lastConnectedDeviceUUID"),
               let savedUUID = UUID(uuidString: savedString),
               let lastAccessory = accessories.first(where: { $0.bluetoothIdentifier == savedUUID }) {
                
                print("Restoring connection to last known device: \(lastAccessory.displayName)")
                savePrismBox(prismBox: lastAccessory)
                
            } else {
                print("No saved device found, defaulting to first in list.")
                if let firstAccessory = accessories.first {
                    savePrismBox(prismBox: firstAccessory)
                }
            }
            
        case .pickerDidPresent:
            pickerDismissed = false
            
        case .pickerDidDismiss:
            pickerDismissed = true
//            authenticated = true // FIX: Reset this so we don't get stuck in pairing mode
            
        case .pickerSetupFailed:
//            authenticated = true
            print("Picker setup failed.")
            
        case .invalidated:
            print("Session invalidated")
            authenticated = false
            
        default:
            print("Received event type \(event)")
        }
    }    #endif

    // MARK: - Connection Management
    func connect() {
        guard let manager = manager, manager.state == .poweredOn, let peripheral = peripheral else {
            return
        }
        manager.connect(peripheral)
    }

    func disconnect() {
        guard let peripheral = peripheral, let manager = manager else { return }
        peripheralConnected = false
        
        // CoreBluetooth safely ignores this if it's already disconnected,
        // but it will properly abort a 'connecting' state.
        manager.cancelPeripheralConnection(peripheral)
    }

    // MARK: - Accessory Session Functions
    func getFadeSpeedForEffect(effect: LightEffects) -> Float {
        switch effect {
        case .colorclock_m: break
        case .custom_m: break
        case .dualmode_m: break
        case .firemode_m: return FireFS
        case .headless_m: return HeadFS
        case .meteorshower_m: return SCFS
        case .rainbowmode_m: return SpecFS
        case .tempclock_m: break
        }
        return 0.0
    }

    // MARK: - BLE Communication: Update Clock
    func sendCommand(command: LightEffects) {
        guard let peripheral = peripheral,
            let characteristic = clockSettingsCharacteristic,
            characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse)
        else {
            disconnectAndRetry()
            return
        }

        struct Command: Codable {
            var command = "effect"
            var value: LightEffects
            var value2: Float
        }
        let toESP = Command(
            value: command,
            value2: getFadeSpeedForEffect(effect: command)
        )
        peripheral.writeValue(encodeTOJSON(any: toESP), for: characteristic, type: .withResponse)
    }

    func sendCommand(command: Modes) {
        guard let peripheral = peripheral,
            let characteristic = clockSettingsCharacteristic,
            characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse)
        else {
            disconnectAndRetry()
            return
        }

        struct Command: Codable {
            var command = "mode"
            var value: Modes
            var value2: Int = 0
        }

        var toESP = Command(value: command)

        if command == .teleportMode {
            toESP.value2 = self.selectedTeleportCity.id
        } else if command == .themeParkMode {
            toESP.value2 = self.selectedPark.id
        }
        peripheral.writeValue(encodeTOJSON(any: toESP), for: characteristic, type: .withResponse)
    }

    func sendCutOff() {
        guard let peripheral = peripheral,
            let characteristic = clockSettingsCharacteristic,
            characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse)
        else {
            disconnectAndRetry()
            return
        }

        struct Command: Codable {
            var command = "cut"
            var value: Int
        }

        var toESP = Command(command: "cut", value: self.cutOff)
        toESP.value = self.cutOff

        peripheral.writeValue(encodeTOJSON(any: toESP), for: characteristic, type: .withResponse)
    }

    func updateLatest() {
        guard let peripheral = peripheral,
            let characteristic = clockSettingsCharacteristic,
            characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse)
        else {
            disconnectAndRetry()
            return
        }

        struct Command: Codable {
            var command = "update"
        }

        let toESP = Command()
        peripheral.writeValue(encodeTOJSON(any: toESP), for: characteristic, type: .withResponse)
    }

    func updateSettings(nameOfSetting: String, value: Float) {
        #if os(iOS)
            if nameOfSetting == "brightness" {
                softImpact.impactOccurred()
            }
        #endif

        guard let peripheral = peripheral,
            let characteristic = clockSettingsCharacteristic,
            characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse)
        else {
            disconnectAndRetry()
            return
        }

        struct Command: Codable {
            var command: String
            var value: Float
        }

        let toESP = Command(command: nameOfSetting, value: value)
        peripheral.writeValue(encodeTOJSON(any: toESP), for: characteristic, type: .withResponse)
    }

    func updateSettings(nameOfSetting: String, value: Int) {
        guard let peripheral = peripheral,
            let characteristic = clockSettingsCharacteristic,
            characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse)
        else {
            disconnectAndRetry()
            return
        }

        struct Command: Codable {
            var command: String
            var value: Int
        }

        let toESP = Command(command: nameOfSetting, value: value)
        peripheral.writeValue(encodeTOJSON(any: toESP), for: characteristic, type: .withResponse)
    }

    func updateSettings(nameOfSetting: String, value: String) {
        guard let peripheral = peripheral,
            let characteristic = clockSettingsCharacteristic,
            characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse)
        else {
            disconnectAndRetry()
            return
        }

        struct Command: Codable {
            var command: String
            var value: String
        }

        let toESP = Command(command: nameOfSetting, value: value)
        peripheral.writeValue(encodeTOJSON(any: toESP), for: characteristic, type: .withResponse)
    }

    func updateMasterEffect(update: MasterEffect) {
        guard let peripheral = peripheral,
            let characteristic = clockSettingsCharacteristic,
            characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse)
        else {
            disconnectAndRetry()
            return
        }

        struct Command: Codable {
            var command = "showSpec"
            var value: MasterEffect
        }

        let toESP = Command(value: update)
        peripheral.writeValue(encodeTOJSON(any: toESP), for: characteristic, type: .withResponse)
    }

    func ping() {
        guard let peripheral = peripheral,
            let characteristic = clockSettingsCharacteristic,
            characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse)
        else {
            disconnectAndRetry()
            return
        }
        
        hasConnected = true

        struct Command: Codable {
            var command = "ping"
            var value = "_"
        }

        let toESP = Command()
        peripheral.writeValue(encodeTOJSON(any: toESP), for: characteristic, type: .withResponse)
    }

    func updateLayout(layout: Int) {
        guard let peripheral = peripheral,
            let characteristic = clockSettingsCharacteristic,
            characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse)
        else {
            disconnectAndRetry()
            return
        }

        struct Command: Codable {
            var command = "layout"
            var value: Int
        }

        let toESP = Command(value: layout)
        peripheral.writeValue(encodeTOJSON(any: toESP), for: characteristic, type: .withResponse)
    }

    func updateCustomColor() {
        guard let peripheral = peripheral,
            let characteristic = clockSettingsCharacteristic,
            characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse)
        else {
            disconnectAndRetry()
            return
        }

        struct Command: Codable {
            var command = "cset"
            var red: Int
            var green: Int
            var blue: Int
        }

        let toESP = Command(red: self.customRed, green: self.customGreen, blue: self.customBlue)
        peripheral.writeValue(encodeTOJSON(any: toESP), for: characteristic, type: .withResponse)
    }
}

// MARK: - CBCentralManagerDelegate

extension ClockSessionManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central manager state: \(central.state)")

        switch central.state {
        case .poweredOn:
            print("power up")
            
            #if os(visionOS)
                // visionOS doesn't use ASK in your code, so keep its scan logic
                central.scanForPeripherals(withServices: [CBUUID(string: ClockSessionManager.SERVICE_UUID)], options: nil)
            #endif
            
            #if os(iOS)
                // FIX: Removed the redundant auto-connect logic here.
                // We now rely purely on AccessorySetupKit's `.activated` or `.accessoryAdded`
                // events to trigger switchToKnownAccessory() or savePrismBox().
                // All we need to do here is check if ASK already queued up a peripheral for us
                // while we were waiting for Bluetooth to power on.
                
                if let peripheralUUID = currentDice?.bluetoothIdentifier, self.peripheral == nil {
                    print("Bluetooth ready. Checking for ASK's queued device...")
                    if let retrieved = central.retrievePeripherals(withIdentifiers: [peripheralUUID]).first {
                        self.peripheral = retrieved
                        self.peripheral?.delegate = self
                        self.connect()
                    }
                }
            #endif

        default:
            // Optional: you might not want to nuke the peripheral on .background or .inactive states,
            // but definitely do it on .poweredOff
            if central.state == .poweredOff {
                peripheral = nil
            }
        }
    }
    
    
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        print("""
            🛰️ Discovered Peripheral:
            Name: \(peripheral.name ?? "Unknown")
            Identifier: \(peripheral.identifier)
            RSSI: \(RSSI)
            Advertisement Data: \(advertisementData)
            """)
        #if os(visionOS)
            self.peripheral = peripheral
            self.peripheral!.delegate = self
            self.connect()
        #endif
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to: \(peripheral.name ?? "Unknown")")
        peripheral.delegate = self
        peripheralConnected = true

        print("Searching for ALL services to verify device type...")
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral: \(peripheral)")
        peripheralConnected = false
        isStandaloneMode = true
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to peripheral: \(peripheral), error: \(error?.localizedDescription ?? "unknown error")")
        
//        if let currentDice = currentDice {
//            switchToKnownAccessory(accessory: currentDice)
//        }
        
        
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        timestamp: CFAbsoluteTime,
        isReconnecting: Bool,
        error: (any Error)?
    ) {
        print("Disconnected from peripheral: \(peripheral), timestamp: \(timestamp), isReconnecting: \(isReconnecting), error: \(error?.localizedDescription ?? "unknown error")")
    }
}

// MARK: - CBPeripheralDelegate

extension ClockSessionManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else {
            print("Service discovery failed: \(error?.localizedDescription ?? "unknown error")")
            return
        }
        
        for service in services {
            #if os(iOS)
                // Register the hardware type permanently bypassing any custom user names
                if service.uuid == PrismDevice.clock.serviceUUID {
                    DispatchQueue.main.async { self.prismDevice = .clock }
                    registerDeviceType(for: peripheral.identifier, type: .clock)
                    print("Verified Hardware: This is a Clock")
                } else if service.uuid == PrismDevice.pencilHolder.serviceUUID {
                    DispatchQueue.main.async { self.prismDevice = .pencilHolder }
                    registerDeviceType(for: peripheral.identifier, type: .pencilHolder)
                    print("Verified Hardware: This is a Pencil Holder")
                }
            #endif

            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil, let characteristics = service.characteristics else {
            print("Error discovering characteristics: \(error?.localizedDescription ?? "unknown")")
            return
        }
        print("Found \(characteristics.count) characteristics")

        #if os(iOS)
            for characteristic in characteristics {
                if characteristic.uuid == CBUUID(string: Self.clockUpdateCharacteristicUUID) {
                    clockSettingsCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                    peripheral.readValue(for: characteristic)
                    print("✅ Characteristic Ready. Sending Ping...")
                    hasConnected = true
                    if !authenticated {
                        print("not authenticated...")
                        presentManagerDeviceView = false

                    }
                    ping()
                }
            }
        #endif

        for characteristic in characteristics where characteristic.uuid == CBUUID(string: Self.vCharacteristic_UUID) {
            vCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
            print("Vision characteristic found")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        #if os(iOS)
            Task {
                if let currentDice = currentDice {
                    do {
                        try await session.finishAuthorization(for: currentDice, settings: .default)
                    } catch {
                        print("Error finishing authorization: \(error.localizedDescription)")
                    }
                }
            }

            if characteristic.uuid == CBUUID(string: Self.clockUpdateCharacteristicUUID) {
                guard let data = characteristic.value else { return }

                if let stateUpdate = try? JSONDecoder().decode(ClockSettings.self, from: data) {
                    syncState(update: stateUpdate)
                    authenticated = true
                } else {
                    print("ClockSettings Decoding error.")
                }
            }
        #endif

        #if os(visionOS)
            if characteristic.uuid == CBUUID(string: Self.vCharacteristic_UUID) {
                guard let data = characteristic.value else { return }

                if let stateUpdate = try? JSONDecoder().decode(VisionInfo.self, from: data) {
                    syncState(update: stateUpdate)
                    authenticated = true
                    if debug.printStateUpdates { print(stateUpdate) }
                } else {
                    print("Clock Info Decoding error.")
                }
            }
        #endif
    }
}

func encodeTOJSON(any: Codable) -> Data {
    do {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(any)

        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Writing with response: \(jsonString)")
        } else {
            print("Writing with response: command updated")
        }
        return jsonData
    } catch {
        print("Failed to encode command: \(error)")
    }
    return Data()
}

extension Int {
    var `true`: Bool { return self != 0 }
    var `false`: Bool { return self == 0 }
}

func returnSecondsFrom(min: Int) -> Double {
    return Double(min * 60)
}
