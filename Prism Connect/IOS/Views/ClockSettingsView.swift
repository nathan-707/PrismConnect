//
//  ClockSettingsView.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 3/6/25.
//

#if os(iOS)

    import SwiftUI

    struct ClockSettingsView: View {
        @EnvironmentObject private var prismSessionManager: ClockSessionManager
        @State var stepWatch: Float = 0.1
        var body: some View {
            Form {
                Section(header: Text("Brightness")) {
                    Toggle(
                        "Auto Dimming",
                        isOn: $prismSessionManager.autoBrightnessOn
                    )
                    .onChange(of: prismSessionManager.autoBrightnessOn) {
                        oldValue,
                        newValue in
                        prismSessionManager.updateSettings(
                            nameOfSetting: "autoBrightnessOn",
                            value: (newValue == false ? 0 : 1)
                        )
                        if !newValue {
                            prismSessionManager.brightness = 1
                        }
                    }

                    if !prismSessionManager.autoBrightnessOn {
                        Slider(
                            value: $prismSessionManager.brightness,
                            in: 0...1
                        )

                        .onChange(of: prismSessionManager.brightness) {
                            oldValue,
                            newValue in

                            if newValue > stepWatch + 0.1 {
                                stepWatch = newValue

                                if newValue > 0.90 {
                                    prismSessionManager.updateSettings(
                                        nameOfSetting: "brightness",
                                        value: 1.0
                                    )
                                } else {
                                    prismSessionManager.updateSettings(
                                        nameOfSetting: "brightness",
                                        value: newValue
                                    )
                                }
                            } else if newValue < stepWatch - 0.1 {
                                stepWatch = newValue

                                if newValue < 0.1 {
                                    prismSessionManager.updateSettings(
                                        nameOfSetting: "brightness",
                                        value: 0
                                    )
                                } else {
                                    prismSessionManager.updateSettings(
                                        nameOfSetting: "brightness",
                                        value: newValue
                                    )
                                }
                            }
                        }
                    }
                }

                Section(header: Text("When Clock Turns On/Off")) {
                    Toggle(
                        "When Room is Dark (Automatic)",
                        isOn: $prismSessionManager.autoOff
                    )
                    .onChange(of: prismSessionManager.autoOff) {
                        oldValue,
                        newValue in
                        prismSessionManager.updateSettings(
                            nameOfSetting: "autoOff",
                            value: (newValue == false ? 0 : 1)
                        )
                    }

                    if !prismSessionManager.autoOff {
                        OnTimePicker()
                        OffTimePicker()
                        Toggle(
                            "Wait Until Room is Dark After Off Time",
                            isOn: $prismSessionManager.semiAutoTurnOff
                        )
                        .onChange(of: prismSessionManager.semiAutoTurnOff) {
                            oldValue,
                            newValue in
                            prismSessionManager.updateSettings(
                                nameOfSetting: "semiAutoTurnOff",
                                value: (newValue == false ? 0 : 1)
                            )
                        }
                    }
                }

                Section(
                    header: Text(
                        prismSessionManager.currentMode == .teleportMode
                            ? "Exit Teleport Mode to Edit" : "Display Layout"
                    )
                ) {
                    LayoutPicker()
                }
                .disabled(
                    prismSessionManager.currentMode == .teleportMode
                        ? true : false
                )

                Section(header: Text("Tele-Settings")) {
                    TourIntervalPicker()

                    Toggle(
                        "Show Teleporting Location Time",
                        isOn: $prismSessionManager.getTimeInTel
                    )
                    .onChange(of: prismSessionManager.getTimeInTel) {
                        oldValue,
                        newValue in
                        prismSessionManager.updateSettings(
                            nameOfSetting: "getTimeInTel",
                            value: (newValue == false ? 0 : 1)
                        )
                        // john

                        if prismSessionManager.currentMode == .teleportMode
                            || prismSessionManager.currentMode == .themeParkMode
                        {
                            heavyImpact.impactOccurred()
                            prismSessionManager.pending = true
                            prismSessionManager.pendingMode = .home
                            prismSessionManager.sendCommand(command: .home)
                        }
                    }
                }

                Section(header: Text("Weather Alerts")) {
                    Toggle(
                        "Hide Alerts",
                        isOn: $prismSessionManager.ignoreAlerts
                    )
                    .onChange(of: prismSessionManager.ignoreAlerts) {
                        oldValue,
                        newValue in

                        prismSessionManager.updateSettings(
                            nameOfSetting: "ignoreAlerts",
                            value: (newValue == false ? 0 : 1)
                        )
                    }

                    Toggle(
                        "Disable Alert Flashing",
                        isOn: $prismSessionManager.disableAlertFlashing
                    )
                    .onChange(of: prismSessionManager.disableAlertFlashing) {
                        oldValue,
                        newValue in
                        prismSessionManager.updateSettings(
                            nameOfSetting: "disaAB",
                            value: (newValue == false ? 0 : 1)
                        )
                    }
                }

                if debug.allowUpdateFromSettings {
                    Button {
                        prismSessionManager.updateLatest()
                    } label: {
                        Text("Check For Update")  //john
                    }
                }
            }
        }
    }

    struct LayoutPicker: View {
        @EnvironmentObject private var prismSessionManager: ClockSessionManager
        var body: some View {
            Stepper(
                String(prismSessionManager.currentLayout),
                value: $prismSessionManager.currentLayout,
                in: 1...12
            )

            .onChange(of: prismSessionManager.currentLayout) {
                oldValue,
                newValue in
                notPendingImpact.impactOccurred()
                prismSessionManager.updateLayout(
                    layout: prismSessionManager.currentLayout
                )
            }

            .onChange(
                of: prismSessionManager.cutOff,
                { oldValue, newValue in
                    print("sending \(prismSessionManager.cutOff)")
                    prismSessionManager.sendCutOff()
                }
            )

        }
    }

    struct OnTimePicker: View {
        @EnvironmentObject private var prismSessionManager: ClockSessionManager
        var body: some View {
            Picker("Clock On Time", selection: $prismSessionManager.onTime) {
                timeView()
            }
            .onChange(of: prismSessionManager.onTime) { oldValue, newValue in
                prismSessionManager.updateSettings(
                    nameOfSetting: "onTime",
                    value: newValue
                )
            }
        }
    }

    struct OffTimePicker: View {
        @EnvironmentObject private var prismSessionManager: ClockSessionManager
        var body: some View {
            Picker("Clock Off Time", selection: $prismSessionManager.offTime) {
                timeView()

            }
            .onChange(of: prismSessionManager.offTime) { oldValue, newValue in
                prismSessionManager.updateSettings(
                    nameOfSetting: "offTime",
                    value: newValue
                )
            }
        }
    }

    struct TourIntervalPicker: View {
        @EnvironmentObject private var prismSessionManager: ClockSessionManager
        var body: some View {
            Picker(
                "World Tour Interval",
                selection: $prismSessionManager.tourInterval
            ) {
                Text("1 Min").tag(60000)
                Text("3 Min").tag(60000 * 3)
                Text("5 Min").tag(60000 * 5)
                Text("10 Min").tag(60000 * 10)
                Text("1 Hr").tag(60000 * 60)
                Text("3 Hr").tag(60000 * 60 * 3)
            }
            .onChange(of: prismSessionManager.tourInterval) {
                oldValue,
                newValue in
                notPendingImpact.impactOccurred()
                prismSessionManager.updateSettings(
                    nameOfSetting: "tourInterval",
                    value: newValue
                )
            }
        }
    }

    struct timeView: View {
        var body: some View {
            Text("1 AM").tag(1)
            Text("2 AM").tag(2)
            Text("3 AM").tag(3)
            Text("4 AM").tag(4)
            Text("5 AM").tag(5)
            Text("6 AM").tag(6)
            Text("7 AM").tag(7)
            Text("8 AM").tag(8)
            Text("9 AM").tag(9)
            Text("10 AM").tag(10)
            Text("11 AM").tag(11)
            Text("12 AM").tag(12)
            Text("1 PM").tag(13)
            Text("2 PM").tag(14)
            Text("3 PM").tag(15)
            Text("4 PM").tag(16)
            Text("5 PM").tag(17)
            Text("6 PM").tag(18)
            Text("7 PM").tag(19)
            Text("8 PM").tag(20)
            Text("9 PM").tag(21)
            Text("10 PM").tag(22)
            Text("11 PM").tag(23)
            Text("(midnight)").tag(24)
        }
    }
#endif
