//
//  Pencil_PickEffectView.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 3/22/26.
//



//
//  PickEffectView.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 3/5/25.
//

import SwiftUI


    struct Pencil_PickEffectView: View {
        @EnvironmentObject private var prismSessionManager: ClockSessionManager
        @State var selectedTile = ColorTile(red: 255, green: 0, blue: 0)

        var body: some View {
            VStack {
                
                if prismSessionManager.status == .connecting {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "wifi.slash")
                            .symbolVariant(.circle)
                            .foregroundStyle(.red)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("No Internet.")
                                .font(.headline)
                                .bold()
                            Text("Color Clock and Weather Mode are disabled until connected.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(10)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(.red.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
                else if prismSessionManager.status == .connected && prismSessionManager.hasGottenWeather {
                    Text(prismSessionManager.location).bold()
                    WeatherInfoView()
                }
                
                Spacer()
                
                if prismSessionManager.masterEffect != .onlyShowW {
                    
                    if prismSessionManager.currentLightEffect == .custom_m {
                        Picker("colorpicker", selection: $selectedTile) {
                            ForEach(ColorTiles) { tile in
                                let color = Color(
                                    red: Double(tile.red),
                                    green: Double(tile.green),
                                    blue: Double(tile.blue)
                                )
                                Rectangle().frame(width: 50, height: 50)
                                    .foregroundColor(color)
                                    .padding(5)
                                    .tag(tile)
                            }
                        }
                        .pickerStyle(.wheel)
                    }

                    EffectSpeedPickerView()
                        .pickerStyle(.palette)
                        .tint(.green)

                    Picker(
                        "picklighteffect",
                        selection: $prismSessionManager.currentLightEffect
                    ) {
                        
                        if prismSessionManager.status == .connected {
                            Text("Custom Color").tag(LightEffects.custom_m)
                            Text("Spectrum").tag(LightEffects.rainbowmode_m)
                            Text("Headless").tag(LightEffects.headless_m)
                            Text("Short Circuit").tag(LightEffects.meteorshower_m)
                            Text("Fire").tag(LightEffects.firemode_m)
                            Text("Color Clock").tag(LightEffects.colorclock_m)
                            Text("Temp Clock").tag(LightEffects.tempclock_m)
                            Text("Dual Mode").tag(LightEffects.dualmode_m)
                        } else {
                            Text("Custom Color").tag(LightEffects.custom_m)
                            Text("Spectrum").tag(LightEffects.rainbowmode_m)
                            Text("Headless").tag(LightEffects.headless_m)
                            Text("Short Circuit").tag(LightEffects.meteorshower_m)
                            Text("Fire").tag(LightEffects.firemode_m)
                            Text("Dual Mode").tag(LightEffects.dualmode_m)
                        }
                        
                    }
                    .pickerStyle(.wheel)
                }
                
                
                if prismSessionManager.status == .connected {
                    Picker(
                        "customOrWeather",
                        selection: $prismSessionManager.masterEffect
                    ) {
                        Text("Effect Only").tag(MasterEffect.fullEff)
                        Text("Both").tag(MasterEffect.showW)
                        Text("Weather Only").tag(MasterEffect.onlyShowW)
                    }.pickerStyle(.palette)
                        .padding(.bottom)
                        .padding(.horizontal)
                }
                
                
            }
            .onChange(
                of: prismSessionManager.currentLightEffect,
                { oldValue, newValue in
                    //            softImpact.impactOccurred(intensity: 0.75)
                    mediumImpact.impactOccurred()
                    prismSessionManager.sendCommand(command: newValue)
                }
            )
            .onChange(of: prismSessionManager.masterEffect) {
                oldValue,
                newValue in
                softImpact.impactOccurred()
                prismSessionManager.updateMasterEffect(
                    update: prismSessionManager.masterEffect
                )
            }
            .onChange(of: selectedTile) { oldValue, newValue in
                softImpact.impactOccurred(intensity: 0.75)
                prismSessionManager.customRed = selectedTile.redmapTo255()
                prismSessionManager.customGreen = selectedTile.greenmapTo255()
                prismSessionManager.customBlue = selectedTile.bluemapTo255()
                prismSessionManager.updateCustomColor()
                prismSessionManager.customColor = CGColor(
                    red: selectedTile.red,
                    green: selectedTile.green,
                    blue: selectedTile.blue,
                    alpha: 1
                )
            }
        }
    }

