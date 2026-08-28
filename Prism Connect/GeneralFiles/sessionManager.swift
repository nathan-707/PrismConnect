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
    case connectedMainMenu, connectedLightEffects, clockSetupWifiView
}

class ClockSessionManager: NSObject, ObservableObject {
    var isShowingWeatherSpace = true
    @Published var presentManagerDeviceView = false
    @Published var lastKnownLat: Double = 0
    @Published var lastKnownLong: Double = 0
    @Published var failedGetHomeWeatherAttempts = 0
    @Published var reportWeatherError = false
    @Published var showConnectToPrismboxButton = false
    @Published var status: WifiStatus = .nothing

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
    
    /// Called from every write guard when the peripheral or characteristic isn't usable.
    /// This used to just print and return, so all 11 call sites silently dropped their
    /// command while logging that they were reconnecting. It now actually bounces the link
    /// and reconnects, throttled so a burst of failed writes can't cause a reconnect storm.
    func disconnectAndRetry() {
        print("Cannot write: peripheral or characteristic unavailable. Attempting reconnect...")

        if let last = lastReconnectAttempt, Date().timeIntervalSince(last) < 5 {
            print("Reconnect throttled (last attempt \(Int(Date().timeIntervalSince(last)))s ago).")
            return
        }

        guard let manager, manager.state == .poweredOn else {
            print("Reconnect skipped: Bluetooth is not powered on.")
            return
        }

        lastReconnectAttempt = Date()

        #if os(visionOS)
            // visionOS finds its clock by scanning, not through AccessorySetupKit, so tearing
            // the peripheral down here has to be paired with restarting discovery — otherwise
            // there's nothing to reconnect to.
            clearActivePeripheral()
            manager.scanForPeripherals(
                withServices: [CBUUID(string: ClockSessionManager.SERVICE_UUID)],
                options: nil
            )
        #endif

        #if os(iOS)
            clearActivePeripheral()

            guard let uuid = currentDice?.bluetoothIdentifier else {
                print("Reconnect skipped: no current accessory to reconnect to.")
                return
            }

            // Let the cancel settle before asking for the peripheral back.
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(500))
                guard let self, let manager = self.manager else { return }

                if let retrieved = manager.retrievePeripherals(withIdentifiers: [uuid]).first {
                    self.peripheral = retrieved
                    self.peripheral?.delegate = self
                    self.connect()
                } else {
                    print("Reconnect failed: peripheral not retrievable (out of range?).")
                }
            }
        #endif
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
    @Published var location: String = ""
    @Published var hasGottenWeather: Bool = false

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
    @Published var deviceType: DeviceVersion = .stereo
    @Published var pencilClock_internet_enabled = false
    @Published var somethingICanUse2: Int = 0 // todo: use this as status of internet (connecting, connected, not connected, failed to connect with given creds)

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


    func syncState(update: ClockSettings) {
        if debug.printStateUpdates {
            print("setting update")
            print(update)
        }
        
        deviceType = DeviceVersion(rawValue: update.e1) ?? .stereo
        pencilClock_internet_enabled = (update.e2 != 0)
        status = WifiStatus(rawValue: update.e3) ?? .neverConnected
        print("status: ", status)
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
                
        location = update.loc ?? ""
        hasGottenWeather = (update.gW != 0)
        
        print(location)
        print(status)
        
        
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
    private var pencilHolderCharacteristic: CBCharacteristic?

    /// Throttle for disconnectAndRetry() so a burst of failed writes can't storm reconnects.
    private var lastReconnectAttempt: Date?
    /// CoreBluetooth's connect() never times out by design. This is our own deadline.
    private var connectWatchdog: Task<Void, Never>?
    #if os(iOS)
        /// Last-resort authorization so a failed connect can't leave ASK spinning forever.
        private var authorizationFallback: Task<Void, Never>?
    #endif

    private static let clockUpdateCharacteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8"
    private static let SERVICE_UUID = "E56A082E-C49B-47CA-A2AB-389127B8ABE3"
    private static let pencilHolderCharacteristicUUID = "beb65483-36e1-4688-b7f5-ea07361b26a8"
    

    #if os(iOS)
        var currentDice: ASAccessory?
        var session = ASAccessorySession()

        // MARK: - Accessory Picker Items
        private static let PencilHolderPickerItem: ASPickerDisplayItem = {
            let descriptor = ASDiscoveryDescriptor()
            descriptor.bluetoothServiceUUID = PrismDevice.pencilHolder.serviceUUID

            // Tell ASK this accessory needs BLE bonding. Without this, ASK doesn't know a
            // passkey is coming, so it never renders its own keypad screen — CoreBluetooth
            // ends up raising the generic "would like to pair with your iPhone" alert
            // instead, whenever a read happens to trip the peripheral's security request.
            descriptor.supportedOptions = [.bluetoothPairingLE]

            return ASPickerDisplayItem(
                name: PrismDevice.pencilHolder.displayName,
                productImage: UIImage(named: PrismDevice.pencilHolder.productImageName)!,
                descriptor: descriptor
            )
        }()

        private static let ClockPickerItem: ASPickerDisplayItem = {
            let descriptor = ASDiscoveryDescriptor()
            descriptor.bluetoothServiceUUID = PrismDevice.clock.serviceUUID

            // See note above — this is what gives you ASK's passkey screen instead of the
            // generic system pairing alert.
            descriptor.supportedOptions = [.bluetoothPairingLE]

            return ASPickerDisplayItem(
                name: PrismDevice.clock.displayName,
                productImage: UIImage(named: PrismDevice.clock.productImageName)!,
                descriptor: descriptor
            )
        }()
    #endif  // os(iOS)

    // MARK: - Initialization
    override init() {
        super.init()
        #if os(iOS)
            self.session.activate(
                on: DispatchQueue.main,
                eventHandler: handleSessionEvent(event:)
            )
        #endif  // os(iOS)
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

        // MARK: - Authorization
        // Both picker items use `.confirmAuthorization`, which parks the accessory in
        // `.awaitingAuthorization` and holds the picker open until we call finishAuthorization.
        // This MUST NOT depend on the accessory answering a read or write — that round trip is
        // what blew past the authorization window on iOS 27. Call it the moment service
        // discovery proves the hardware is ours.
        @MainActor
        private func finishAuthorizationIfNeeded() async {
            guard let accessory = currentDice else {
                print("finishAuthorization skipped: no current accessory.")
                return
            }

            guard accessory.state == .awaitingAuthorization else {
                // Already authorized, or never needed confirmation. Nothing to do.
                authorizationFallback?.cancel()
                return
            }

            do {
                try await session.finishAuthorization(for: accessory, settings: .default)
                print("✅ Authorization finished for \(accessory.displayName)")
                authorizationFallback?.cancel()
                authenticated = true
            } catch {
                print("❌ finishAuthorization failed: \(error.localizedDescription)")
            }
        }

        // MARK: - Accessory Switching
        func switchToKnownAccessory(accessory: ASAccessory) {
            print("Switching to \(accessory.displayName)...")

                let targetDevice = getDeviceType(for: accessory.bluetoothIdentifier)
                
                // FIX: fully tear down the old link before overwriting. disconnect() alone
                // left `peripheral` pointing at the previous box, which stranded the switch
                // whenever Bluetooth wasn't powered on yet.
                clearActivePeripheral()
                
                // FIX (iOS 27): do NOT gate this on `authenticated`. During a real pairing
                // `authenticated` is false, so currentDice was never set here — and
                // centralManagerDidUpdateState reads currentDice?.bluetoothIdentifier to find
                // the peripheral ASK queued for us. It only worked because savePrismBox
                // happened to run immediately afterwards.
                currentDice = accessory
                persistLastDevice(accessory: accessory)
            
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

            clearActivePeripheral()

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

            clearActivePeripheral()

            session.removeAccessory(currentDice) { error in
                if let error {
                    print("❌ removeAccessory failed: \(error.localizedDescription)")
                    return  // Don't tear down local state for a removal that didn't happen.
                }

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

                // Keep the central manager alive — nil'ing it left connect()/disconnect()
                // permanently inert. Instead, fall back to another paired box if one exists,
                // so removing one of two devices doesn't drop the user to "No PrismBox".
                if let next = self.session.accessories.first {
                    print("Falling back to remaining accessory: \(next.displayName)")
                    self.switchToKnownAccessory(accessory: next)
                } else {
                    self.hasConnected = false
                }
            }
        }

        /// Safety net against the infinite "Pairing accessory" spinner.
        ///
        /// The normal path authorizes from didDiscoverServices. But if the connection to the
        /// new box fails, or discovery never returns, that never runs and ASK spins forever
        /// with no way out. This authorizes anyway after a grace period.
        ///
        /// Skipping our own verification is safe here: ASK only ever offers accessories that
        /// already matched the descriptor's private service UUID, so it is a PrismBox.
        private func scheduleAuthorizationFallback(for accessory: ASAccessory) {
            authorizationFallback?.cancel()
            authorizationFallback = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(12))
                guard !Task.isCancelled, let self else { return }
                guard accessory.state == .awaitingAuthorization else { return }

                print("⏱️ Service discovery didn't authorize in time — authorizing anyway.")
                do {
                    try await self.session.finishAuthorization(for: accessory, settings: .default)
                    self.authenticated = true
                } catch {
                    print("❌ Fallback finishAuthorization failed: \(error.localizedDescription)")
                }
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
            
            // Stop the boot-spam loop, but never at the cost of an in-flight pairing.
            //
            // This used to read `authenticated == false || currentDice == nil`, which only
            // worked for the FIRST box: after that currentDice is set and `authenticated`
            // is true, so adding a second box fell into the else branch and we never
            // authorized it — ASK sat on "Pairing accessory" forever waiting on us.
            //
            // `.awaitingAuthorization` is ASK's own statement that it is blocked on this
            // app, so key off that rather than a flag we maintain by hand.
            if prismBox.state == .awaitingAuthorization || currentDice == nil {
                switchToKnownAccessory(accessory: prismBox)
                savePrismBox(prismBox: prismBox)
                scheduleAuthorizationFallback(for: prismBox)
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

            // If the user backed out of the picker, clear the pairing flag or ContentView
            // stays pinned on the setup screen forever (it gates on pickerDismissed &&
            // authenticated). Skip it if an authorization is genuinely still in flight.
            if currentDice?.state != .awaitingAuthorization {
                authenticated = true
            }

        case .pickerSetupFailed:
            print("Picker setup failed.")
            // Setup failed, so nothing is awaiting authorization — don't leave the app stuck.
            authenticated = true
            
        case .invalidated:
            print("Session invalidated")
            authenticated = false
            
        default:
            print("Received event type \(event)")
        }
    }
    #endif  // os(iOS)

    // MARK: - Connection Management
    func connect() {
        guard let manager = manager, manager.state == .poweredOn, let peripheral = peripheral else {
            return
        }
        manager.connect(peripheral)
        startConnectWatchdog(for: peripheral)
    }

    func disconnect() {
        guard let peripheral = peripheral, let manager = manager else { return }
        peripheralConnected = false
        connectWatchdog?.cancel()

        // CoreBluetooth safely ignores this if it's already disconnected,
        // but it will properly abort a 'connecting' state.
        manager.cancelPeripheralConnection(peripheral)
    }

    /// Tears the current link down AND forgets what it was pointing at.
    ///
    /// Use this instead of disconnect() whenever we're switching to a different accessory.
    /// disconnect() leaves `peripheral` pointing at the old box, which makes the
    /// `self.peripheral == nil` guard in centralManagerDidUpdateState skip the reconnect —
    /// so a switch made while Bluetooth wasn't powered on would silently never happen.
    private func clearActivePeripheral() {
        connectWatchdog?.cancel()

        if let peripheral, let manager {
            manager.cancelPeripheralConnection(peripheral)
        }

        peripheral = nil
        peripheralConnected = false
        clockSettingsCharacteristic = nil
        pencilHolderCharacteristic = nil
    }

    /// CoreBluetooth's connect() waits forever if the box is off or out of range, and
    /// didFailToConnect never fires in that case. Without this the app just sits there.
    private func startConnectWatchdog(for target: CBPeripheral) {
        connectWatchdog?.cancel()
        connectWatchdog = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(20))
            guard !Task.isCancelled, let self else { return }
            guard self.peripheralConnected == false,
                  self.peripheral?.identifier == target.identifier else { return }

            print("⏱️ Connect timed out for \(target.identifier). Giving up.")
            self.manager?.cancelPeripheralConnection(target)
            self.isStandaloneMode = true
        }
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

        // hasConnected is no longer set here — it would defeat the picker guard in
        // didDiscoverCharacteristicsFor, since ping() is called immediately after it.

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
            #endif  // os(iOS)

        default:
            // Note: under AccessorySetupKit a "poweredOff" here often isn't the user's radio
            // at all — it's ASK revoking our Bluetooth grant. Either way the link is gone,
            // so clear everything that describes it rather than just the peripheral (which
            // used to leave peripheralConnected == true and the UI claiming it was live).
            if central.state == .poweredOff {
                clearActivePeripheral()
                isStandaloneMode = true
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
        // Ignore callbacks for a box we've already switched away from. Without this, a late
        // event from the previous accessory stomps the state of the new one.
        guard peripheral.identifier == self.peripheral?.identifier else {
            print("Ignoring didConnect from stale peripheral \(peripheral.identifier)")
            return
        }

        print("Connected to: \(peripheral.name ?? "Unknown")")
        connectWatchdog?.cancel()
        peripheral.delegate = self
        peripheralConnected = true

        print("Searching for ALL services to verify device type...")
        peripheral.discoverServices(nil)
    }

    // NOTE: centralManager(_:didDisconnectPeripheral:error:) used to live here. It was
    // deprecated in iOS 18, and when both signatures are implemented CoreBluetooth only
    // calls the newer timestamp/isReconnecting one below — so this body was dead code on
    // any modern iOS. Its state resets now live in that handler.

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard peripheral.identifier == self.peripheral?.identifier else {
            print("Ignoring didFailToConnect from stale peripheral \(peripheral.identifier)")
            return
        }

        print("Failed to connect to peripheral: \(peripheral), error: \(error?.localizedDescription ?? "unknown error")")
        connectWatchdog?.cancel()
        peripheralConnected = false
        isStandaloneMode = true
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        timestamp: CFAbsoluteTime,
        isReconnecting: Bool,
        error: (any Error)?
    ) {
        // Critical when switching boxes: switchToKnownAccessory() cancels the old link and
        // connects to the new one in the same run loop, so the OLD box's disconnect can land
        // after the NEW one is already up. Without this guard it would wipe the new
        // connection's characteristics and flip the app to standalone.
        guard peripheral.identifier == self.peripheral?.identifier else {
            print("Ignoring didDisconnect from stale peripheral \(peripheral.identifier)")
            return
        }

        print("Disconnected from peripheral: \(peripheral), timestamp: \(timestamp), isReconnecting: \(isReconnecting), error: \(error?.localizedDescription ?? "unknown error")")

        peripheralConnected = false

        // If CoreBluetooth is auto-reconnecting, don't drop the app into standalone mode —
        // we'll get didConnect again shortly.
        if !isReconnecting {
            isStandaloneMode = true
            clockSettingsCharacteristic = nil
            pencilHolderCharacteristic = nil
        }
    }
}

// MARK: - CBPeripheralDelegate

extension ClockSessionManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else {
            print("Service discovery failed: \(error?.localizedDescription ?? "unknown error")")
            return
        }
        
        var verifiedPrismHardware = false

        for service in services {
            #if os(iOS)
                // Register the hardware type permanently bypassing any custom user names
                if service.uuid == PrismDevice.clock.serviceUUID {
                    DispatchQueue.main.async { self.prismDevice = .clock }
                    registerDeviceType(for: peripheral.identifier, type: .clock)
                    print("Verified Hardware: This is a Clock")
                    verifiedPrismHardware = true
                } else if service.uuid == PrismDevice.pencilHolder.serviceUUID {
                    DispatchQueue.main.async { self.prismDevice = .pencilHolder }
                    registerDeviceType(for: peripheral.identifier, type: .pencilHolder)
                    print("Verified Hardware: This is a Pencil Holder")
                    verifiedPrismHardware = true
                }
            #endif  // os(iOS)

            peripheral.discoverCharacteristics(nil, for: service)
        }

        #if os(iOS)
            // THE FIX: we have proven this is our hardware, so confirm authorization now.
            // Waiting for the characteristic read to come back (the old behaviour) is what
            // let ASK's authorization window expire on iOS 27, which removed the accessory
            // and revoked our Bluetooth grant — the phantom "poweredOff" in the log.
            if verifiedPrismHardware {
                Task { await finishAuthorizationIfNeeded() }
            }
        #endif  // os(iOS)
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

                    // FIX: don't flip ContentView into ManageDeviceView while the ASK picker
                    // sheet is still on screen. Presenting over the picker is what the
                    // AccessorySetupUI presenter was complaining about in the log. hasConnected
                    // is also set in didUpdateValueFor once the box actually answers, which
                    // covers the pairing case.
                    if pickerDismissed, currentDice?.state != .awaitingAuthorization {
                        hasConnected = true
                    }

                    if !authenticated {
                        print("not authenticated...")
                        presentManagerDeviceView = false
                    }
                    ping()
                }
                
                // --> ADDED: Discover and subscribe to the Pencil Holder characteristic
                                if characteristic.uuid == CBUUID(string: Self.pencilHolderCharacteristicUUID) {
                                    pencilHolderCharacteristic = characteristic
                                    peripheral.setNotifyValue(true, for: characteristic)
                                    print("✏️ Pencil Holder Characteristic Ready.")
                                }
            }
        #endif  // os(iOS)

   
    }

    // Diagnostic: tells you whether GATT writes are actually completing before authorization.
    // If you see the ping write go out but never land here, writes are being blocked while the
    // accessory is still .awaitingAuthorization — i.e. a deadlock rather than a slow race.
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            print("❌ Write failed for \(characteristic.uuid): \(error.localizedDescription)")
        } else {
            print("↩︎ Write acknowledged for \(characteristic.uuid)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        #if os(iOS)
            // REMOVED (iOS 27 fix): finishAuthorization used to run here, on every single
            // characteristic update. That made authorization depend on the accessory
            // answering — which is exactly the round trip that timed out — and it also
            // re-authorized an already-authorized accessory forever after, throwing each
            // time. Authorization now happens in didDiscoverServices.

            if characteristic.uuid == CBUUID(string: Self.clockUpdateCharacteristicUUID) {
                guard let data = characteristic.value else { return }

                if let stateUpdate = try? JSONDecoder().decode(ClockSettings.self, from: data) {
                    syncState(update: stateUpdate)
                    authenticated = true
                    hasConnected = true
                } else {
                    print("ClockSettings Decoding error.")
                }
            }
        
//
//        else if characteristic.uuid == CBUUID(string: Self.pencilHolderCharacteristicUUID) {
//                print("read pencil characteristic")
//
//                guard let data = characteristic.value else { return }
//
//                if let stateUpdate = try? JSONDecoder().decode(PencilHolderSettings.self, from: data) {
//                    if let decodedEffect = LightEffects(rawValue: stateUpdate.effect) {
//                        print("Successfully decoded pencil effect: \(decodedEffect)")
//
//                        Task { @MainActor in
//                            self.currentLightEffect = decodedEffect
//                            self.customRed = stateUpdate.cR
//                            self.customGreen = stateUpdate.cG
//                            self.customBlue = stateUpdate.cB
//                            self.masterEffect = MasterEffect(rawValue: stateUpdate.masterEffect) ?? .showW
//                            self.status = WifiStatus(rawValue: stateUpdate.e3) ?? .neverConnected
//                            self.autoBrightnessOn = (stateUpdate.aBr != 0)
//                            self.brightness = stateUpdate.br
//                            self.clock_weather = WeatherLight.from(stateUpdate.weather) ?? .CLEAR_DAY
//                            self.clock_temperature = stateUpdate.temp
//                            self.deviceType = DeviceVersion(rawValue: stateUpdate.e1) ?? .stereo
//                            self.location = stateUpdate.loc
//                            self.hasGottenWeather = (stateUpdate.gW != 0)
//                            print("city: ")
//                            print(stateUpdate.loc)
//                            print("has gotten weather ", self.hasGottenWeather)
//
//                            customColor = CGColor(
//                                red: CGFloat(stateUpdate.cR) / 255,
//                                green: CGFloat(stateUpdate.cG) / 255,
//                                blue: CGFloat(stateUpdate.cB) / 255,
//                                alpha: 1
//                            )
//
//                            tempClockColor = CGColor(
//                                red: CGFloat(stateUpdate.tempR) / 255,
//                                green: CGFloat(stateUpdate.tempG) / 255,
//                                blue: CGFloat(stateUpdate.tempB) / 255,
//                                alpha: 1
//                            )
//                        }
//                    } else {
//                        print("Received an unknown effect integer: \(stateUpdate.effect)")
//                    }
//                } else {
//                    print("Failed to decode pencil settings JSON.")
//                }
//            }
              
        #endif  // os(iOS)


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

