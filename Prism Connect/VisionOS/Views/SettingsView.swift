//
//  SettingsView.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 9/4/25.
//

import SwiftData
import SwiftUI
import UIKit

#if os(visionOS)
let lowestGainDecible: Double = 40

    struct SettingsView: View {
        @Environment(\.scenePhase) private var scenePhase
        @Environment(\.dismissWindow) private var dismissWindow
        @Query var dataModelQuery: [DataModel]
        @Environment(\.modelContext) var modelContext
        @EnvironmentObject private var prismSessionManager: ClockSessionManager
        @EnvironmentObject private var storeModel: Store

        @State var sliderValue: Double = 0

        var body: some View {
            Form {
                Section(header: Text("Layout")) {
                    HStack {
                        Text("Clock Size")
                        Spacer()
                        Slider(value: $prismSessionManager.timeScale, in: 1...3)
                            .frame(width: 600)
                    }

                    Toggle(isOn: $prismSessionManager.showTemperature) {
                        Text("Show Temperature")
                    }

                    if prismSessionManager.showTemperature {
                        HStack {
                            Text("Temperature Size")
                            Spacer()
                            Slider(value: $prismSessionManager.tempScale, in: 1...2)
                                .frame(width: 600)
                        }
                    }
                    
                    
                    Toggle(isOn: $prismSessionManager.showFunfact) {
                        Text("Show Funfacts in Teleport")
                    }
                    
                
                }
                .padding(.top, 10)

                Section(header: Text("Audio")) {
                    Toggle(isOn: $prismSessionManager.soundOn) {
                        Text("Rain and Snow Audio")
                    }

                    if prismSessionManager.soundOn {
                        HStack {
                            Text("Volume")
                            Spacer()

                            Slider(
                                value: $sliderValue,
                                in: 0...lowestGainDecible,
                                step: 1
                            )
                            .frame(width: 600)
                        }
                    }
                }

                Section(header: Text("Units")) {
                    Toggle(isOn: $prismSessionManager.imperial) {
                        Text("Imperial")
                    }
                }

                Section(
                    header: Text(
                        "Extra Features"
                    )
                ) {

                    if !storeModel.upgraded {
                        UpgradeInfoView()
                    }

                    ColorPicker(
                        selection: $prismSessionManager.userColor,
                        supportsOpacity: false
                    ) {
                        Text(
                            "Customize Color of Text"
                        )

                    }.disabled(!storeModel.upgraded)

                    Toggle(isOn: $prismSessionManager.showBattery) {
                        Text("Show Battery Level")
                    }.disabled(!storeModel.upgraded)

                    Picker(
                        "Tour Interval",
                        selection: $prismSessionManager
                            .standalone_worldTourInterval_Mins,
                    ) {
                        Text("1 Min").tag(1)
                        Text("5 Mins").tag(5)
                        Text("10 Mins").tag(10)
                        Text("15 Mins").tag(15)
                        Text("30 Mins").tag(30)
                        Text("1 Hr").tag(60)
                    }.disabled(!storeModel.upgraded)
                }
            }
            .glassBackgroundEffect()

            .onAppear {
                sliderValue =
                    prismSessionManager.rainSnowGain + lowestGainDecible
            }

            .onChange(
                of: sliderValue,
                { oldValue, newValue in
                    prismSessionManager.rainSnowGain =
                        sliderValue - lowestGainDecible
                    print(prismSessionManager.rainSnowGain)
                }
            )

            .onChange(
                of: scenePhase,
                { oldValue, newValue in
                    if newValue == .background || newValue == .inactive {
                        prismSessionManager.presentSettings = false
                    }
                }
            )

            .onChange(
                of: prismSessionManager.presentSettings,
                { oldValue, newValue in
                    if !newValue {
                        dismissWindow()
                    }
                }
            )

            .onChange(of: prismSessionManager.timeScale) {
                saveSettings()
            }
            .onChange(of: prismSessionManager.tempScale) {
                saveSettings()
            }
            .onChange(of: prismSessionManager.imperial) {
                saveSettings()
            }
            .onChange(of: prismSessionManager.userColor) {
                saveSettings()
            }
            .onChange(of: prismSessionManager.showBattery) {
                saveSettings()
            }
            
            .onChange(of: prismSessionManager.showTemperature, { oldValue, newValue in
                saveSettings()
            })
            .onChange(of: prismSessionManager.soundOn, {
                saveSettings()
            })
            
            .onChange(of: prismSessionManager.rainSnowGain, {
                saveSettings()
            })
            
            .onChange(of: prismSessionManager.standalone_worldTourInterval_Mins)
            {
                saveSettings()
            }
            .onChange(of: prismSessionManager.showFunfact) {
                saveSettings()
            }
        }

        func saveSettings() {

            guard let savedDataModel = dataModelQuery.first else { return }

            if prismSessionManager.imperial != savedDataModel.imperial {
                savedDataModel.imperial = prismSessionManager.imperial
            }

            if prismSessionManager.showTemperature != savedDataModel.showTemperature {
                savedDataModel.showTemperature = prismSessionManager.showTemperature
            }

            if prismSessionManager.timeScale != dataModelQuery.first?.timeScale
            {
                savedDataModel.timeScale = prismSessionManager.timeScale
            }

            if prismSessionManager.tempScale != dataModelQuery.first?.tempScale
            {
                savedDataModel.tempScale = prismSessionManager.tempScale
            }

            if prismSessionManager.showBattery != savedDataModel.showBattery {
                savedDataModel.showBattery =
                    prismSessionManager.showBattery
            }

            if prismSessionManager.showTemperature
                != savedDataModel.showTemperature
            {
                savedDataModel.showTemperature =
                    prismSessionManager.showTemperature
            }

            if prismSessionManager.soundOn != savedDataModel.soundOn {
                savedDataModel.soundOn = prismSessionManager.soundOn
            }

            if prismSessionManager.standalone_worldTourInterval_Mins != savedDataModel.tourInterval {
                savedDataModel.tourInterval = prismSessionManager.standalone_worldTourInterval_Mins
            }

            if prismSessionManager.rainSnowGain != savedDataModel.volume {
                savedDataModel.volume = prismSessionManager.rainSnowGain
            }
            
            if prismSessionManager.showFunfact != savedDataModel.showFunfact {
                savedDataModel.showFunfact = prismSessionManager.showFunfact
            }
            
            // Save RGB values of the custom color selection
            let uiColor = UIColor(prismSessionManager.userColor)
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0

            if uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
                if savedDataModel.cRed != Double(r) {
                    savedDataModel.cRed = Double(r)
                }
                if savedDataModel.cGreen != Double(g) {
                    savedDataModel.cGreen = Double(g)
                }
                if savedDataModel.cBlue != Double(b) {
                    savedDataModel.cBlue = Double(b)
                }
            }

            do {
                try modelContext.save()
            } catch {
                print("error saving")
            }
        }

        //        func saveSettings() {
        //
        //            guard let savedDataModel = dataModelQuery.first else {return }
        //
        //
        //
        //
        //
        //                if prismSessionManager.imperial != savedDataModel.imperial {
        //                    savedDataModel.imperial = prismSessionManager.imperial
        //                }
        //
        //
        //
        //            if prismSessionManager.imperial != dataModelQuery.first?.imperial {
        //                dataModelQuery.first?.imperial = prismSessionManager.imperial
        //            }
        //
        //            if prismSessionManager.timeScale != dataModelQuery.first?.timeScale
        //            {
        //                dataModelQuery.first?.timeScale = prismSessionManager.timeScale
        //            }
        //
        //            if prismSessionManager.tempScale != dataModelQuery.first?.tempScale
        //            {
        //                dataModelQuery.first?.tempScale = prismSessionManager.tempScale
        //            }
        //
        //            if prismSessionManager.showBattery
        //                != dataModelQuery.first?.showBattery
        //            {
        //                dataModelQuery.first?.showBattery =
        //                    prismSessionManager.showBattery
        //            }
        //
        //            if prismSessionManager.showTemperature != dataModelQuery.first?.showTemperature {
        //                dataModelQuery.first?.showTemperature = prismSessionManager.showTemperature
        //            }
        //
        //            // Save RGB values of the custom color selection
        //            let uiColor = UIColor(prismSessionManager.userColor)
        //            var r: CGFloat = 0
        //            var g: CGFloat = 0
        //            var b: CGFloat = 0
        //            var a: CGFloat = 0
        //
        //            if uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
        //                if dataModelQuery.first?.cRed != Double(r) {
        //                    dataModelQuery.first?.cRed = Double(r)
        //                }
        //                if dataModelQuery.first?.cGreen != Double(g) {
        //                    dataModelQuery.first?.cGreen = Double(g)
        //                }
        //                if dataModelQuery.first?.cBlue != Double(b) {
        //                    dataModelQuery.first?.cBlue = Double(b)
        //                }
        //            }
        //
        //            do {
        //                try modelContext.save()
        //            } catch {
        //                print("error saving")
        //            }
        //        }
    }
#endif
