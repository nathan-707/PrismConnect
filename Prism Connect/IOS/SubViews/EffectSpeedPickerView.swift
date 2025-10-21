//
//  EffectSpeedPickerView.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 3/12/25.
//

import SwiftUI

#if os(iOS)
    struct EffectSpeedPickerView: View {
        @EnvironmentObject private var prismSessionManager: ClockSessionManager
        @State var speed: Float = 0
        let min: Float = 0
        let max: Float = 90
        let step: Float = 30
        let speedFont: Font = .headline
        let speedTint: Color = .green

        var body: some View {
            if prismSessionManager.currentLightEffect != .colorclock_m
                && prismSessionManager.currentLightEffect != .tempclock_m
                && prismSessionManager.currentLightEffect != .dualmode_m
                && prismSessionManager.currentLightEffect != .custom_m
            {

                Text("SPEED")
                    .foregroundStyle(speedTint)
                    .font(speedFont)
                    .bold()
                    .padding()  // caped top, bottom, speed to secondary.
            }

            if prismSessionManager.currentLightEffect == .dualmode_m {
                HStack {
                    VStack {
                        //                    Text("TOP").bold()
                        HStack {

                            Text("TOP:")
                                .foregroundStyle(.secondary)
                                .bold()

                            Picker(
                                "largeMode",
                                selection: $prismSessionManager.largeMode
                            ) {
                                Text("Custom Color").tag(6)
                                Text("Spectrum").tag(1)
                                Text("Headless").tag(2)
                                Text("Short Circuit").tag(3)
                                Text("Fire").tag(7)
                                Text("Color Clock").tag(4)
                                Text("Temp Clock").tag(5)
                            }
                            .pickerStyle(.menu)
                        }

                        HStack {

                            Text("BOTTOM:")
                                .foregroundStyle(.secondary)
                                .bold()

                            Picker(
                                "smallMode",
                                selection: $prismSessionManager.smallMode
                            ) {
                                Text("Custom Color").tag(6)
                                Text("Spectrum").tag(1)
                                Text("Headless").tag(2)
                                Text("Short Circuit").tag(3)
                                Text("Fire").tag(7)
                                Text("Color Clock").tag(4)
                                Text("Temp Clock").tag(5)
                            }

                            .pickerStyle(.menu)

                        }
                    }
                }
                .onChange(of: prismSessionManager.smallMode) {
                    oldValue,
                    newValue in
                    notPendingImpact.impactOccurred()
                    prismSessionManager.updateSettings(
                        nameOfSetting: "smallMode",
                        value: newValue
                    )
                }
                .onChange(of: prismSessionManager.largeMode) {
                    oldValue,
                    newValue in
                    notPendingImpact.impactOccurred()
                    prismSessionManager.updateSettings(
                        nameOfSetting: "largeMode",
                        value: newValue
                    )
                }
            } else if prismSessionManager.currentLightEffect == .rainbowmode_m {
                Picker(
                    "",
                    selection: $prismSessionManager.SpecFS,
                    content: {
                        Text("Fast").tag(Float(0.0))
                        Text("Medium").tag(Float(15.0))
                        Text("Slow").tag(Float(30.0))
                        Text("Sloww").tag(Float(45.0))
                    }
                )

                .onChange(of: prismSessionManager.SpecFS) {
                    oldValue,
                    newValue in
                    print(newValue)
                    speed = newValue
                    lightImpact.impactOccurred()
                    prismSessionManager.sendCommand(command: .rainbowmode_m)
                }.onAppear {
                    speed = prismSessionManager.SpecFS
                }
                .padding(.leading)
                .padding(.trailing)
            } else if prismSessionManager.currentLightEffect == .headless_m {
                Picker(
                    "",
                    selection: $prismSessionManager.HeadFS,
                    content: {
                        Text("Fast").tag(Float(0.0))
                        Text("Medium").tag(Float(15))
                        Text("Slow").tag(Float(30))
                        Text("Sloww").tag(Float(55))
                    }
                )
                .onChange(of: prismSessionManager.HeadFS) {
                    oldValue,
                    newValue in
                    speed = newValue
                    lightImpact.impactOccurred()
                    prismSessionManager.sendCommand(command: .headless_m)
                }.onAppear {
                    speed = prismSessionManager.HeadFS
                }
                .padding(.leading)
                .padding(.trailing)
            } else if prismSessionManager.currentLightEffect == .meteorshower_m
            {
                Picker(
                    "",
                    selection: $prismSessionManager.SCFS,
                    content: {
                        Text("Fast").tag(Float(0.0))
                        Text("Medium").tag(Float(30.0))
                        Text("Slow").tag(Float(60.0))
                        Text("Sloww").tag(Float(90.0))
                    }
                )

                .onChange(of: prismSessionManager.SCFS) { oldValue, newValue in
                    print(newValue)
                    speed = newValue
                    lightImpact.impactOccurred()
                    prismSessionManager.sendCommand(command: .meteorshower_m)
                }.onAppear {
                    speed = prismSessionManager.SCFS
                }
                .padding(.leading)
                .padding(.trailing)
            } else if prismSessionManager.currentLightEffect == .firemode_m {

                Picker(
                    "",
                    selection: $prismSessionManager.FireFS,
                    content: {
                        Text("Fast").tag(Float(0.0))
                        Text("Medium").tag(Float(30))
                        Text("Slow").tag(Float(60))
                        Text("Sloww").tag(Float(90))
                    }
                )

                .onChange(of: prismSessionManager.FireFS) {
                    oldValue,
                    newValue in
                    speed = newValue
                    lightImpact.impactOccurred()
                    prismSessionManager.sendCommand(command: .firemode_m)
                }.onAppear {
                    speed = prismSessionManager.FireFS
                }
                .padding(.leading)
                .padding(.trailing)
            }
        }
    }

    #Preview {
        EffectSpeedPickerView()
    }
#endif
