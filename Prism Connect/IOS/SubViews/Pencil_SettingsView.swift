//
//  Pencil_SettingsView.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 3/23/26.
//
import SwiftUI

struct Pencil_SettingsView: View {
    @EnvironmentObject private var prismSessionManager: ClockSessionManager
    @State var stepWatch: Float = 0.1
    
    // Computed property to check if the session is currently active or connecting
    private var isConnected: Bool {
        prismSessionManager.status == .connected || prismSessionManager.status == .connecting
    }

    var body: some View {
        Form {
            Section(header: Text("Brightness")) {
                Toggle(
                    "Auto Dim When Dark Outside",
                    isOn: $prismSessionManager.autoBrightnessOn
                )
                .disabled(!isConnected) // Disable when NOT connected
                .onChange(of: prismSessionManager.autoBrightnessOn) { oldValue, newValue in
                    prismSessionManager.updateSettings(
                        nameOfSetting: "autoBrightnessOn",
                        value: (newValue == false ? 0 : 1)
                    )
                    if !newValue {
                        prismSessionManager.brightness = 1
                    }
                }
                
                // Show the internet setup note if not connected
                if !isConnected {
                    Text("Set up internet to enable these options")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !prismSessionManager.autoBrightnessOn {
                    Slider(
                        value: $prismSessionManager.brightness,
                        in: 0...1
                    )
                    .onChange(of: prismSessionManager.brightness) { oldValue, newValue in
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
            
            // On/Off Times Section (Always visible, but disabled when offline)
            Section(header: Text("On/Off Times")) {
                if !prismSessionManager.autoOff {
                    OnTimePicker()
                        .disabled(!isConnected)
                    OffTimePicker()
                        .disabled(!isConnected)
                }
                
                // Show the internet setup note if not connected
                if !isConnected {
                    Text("Set up internet to enable these options")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if debug.allowUpdateFromSettings {
                Button {
                    prismSessionManager.updateLatest()
                } label: {
                    Text("Check For Update")  //john
                }
            }
            
            if debug.showSetLC {
                Button {
                    prismSessionManager.updateSettings(
                        nameOfSetting: "setLC",
                        value: 1
                    )
                } label: {
                    Text("ENABLE LC")
                }
            }
            
            PencilHolderCustomView()
        }
    }
}
