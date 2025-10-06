//
//  VisionClockInfoView.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 9/13/25.
//

import SwiftUI

#if os(visionOS)
    import UIKit
    import Combine

    let scaleMul: Double = 5

    struct VisionClockInfoView: View {
        @State private var currentDate = Date()
        @State private var clockTime: String = "1:00"
        @State private var timer: Timer? = nil
        @State private var localFunfact = "no fun fact"
        @EnvironmentObject private var prismSessionManager: ClockSessionManager
        @State private var syncTimeTask: Task<Void, Never>?
        @State private var deviceBatteryLevel: Float = -1

        var body: some View {
            VStack {
                Rectangle().frame(width: 1000, height: 0).foregroundStyle(
                    .clear
                )

                if prismSessionManager.isStandaloneMode == false
                    && prismSessionManager.pending
                {
                    ProgressView()
                }

                Text(prismSessionManager.timeFormatted())
                    .font(.extraLargeTitle)
                    .foregroundStyle(prismSessionManager.userColor)
                    .bold()
                    .scaleEffect(prismSessionManager.timeScale)
                    .alignmentGuide(.controlPanelGuide) { context in
                        context[HorizontalAlignment.center]
                    }
                    .padding(prismSessionManager.timeScale * scaleMul)

                if prismSessionManager.showTemperature {
                    Text(
                        String(prismSessionManager.clock_temperature)
                            + (prismSessionManager.imperial ? " F" : " C")
                    )
                    .scaleEffect(prismSessionManager.tempScale)
                    //                    .bold()
                    .foregroundColor(
                        Color(
                            prismSessionManager.userColor
                        )
                    )
                    .font(.extraLargeTitle2)
                    .padding(10)

                }

                //                if prismSessionManager.currentMode == .teleportMode && prismSessionManager.isStandaloneMode == false {
                //                    Text(prismSessionManager.CurrentTeleportation.city + ", " + prismSessionManager.CurrentTeleportation.territory)
                //                    .font(.headline)
                //                    .foregroundColor(prismSessionManager.userColor)
                //                    .bold()
                //                    .padding(5)
                //
                //                }
                //
                //               else

                if prismSessionManager.currentMode == .teleportMode
                    && !prismSessionManager.isStandaloneMode

                    || prismSessionManager.standalonemode_Mode == .teleportMode
                        && prismSessionManager.isStandaloneMode
                {

                    Text(
                        prismSessionManager.CurrentTeleportation.city + ", "
                            + prismSessionManager.CurrentTeleportation.territory
                    )
                    .font(.headline)
                    .foregroundColor(prismSessionManager.userColor)
                    .bold()
                    .padding(5)
                    //                    .glassBackgroundEffect(in: .rect(cornerRadius: 200))

                    if prismSessionManager.showFunfact {
                        Text(localFunfact)
                            .padding(.bottom)
                            .foregroundStyle(.secondary)
                        Button("", systemImage: "arrow.clockwise.circle") {
                            localFunfact = getRandomFactFromLocal()
                        }

                    }

                } else if prismSessionManager.currentMode == .themeParkMode
                    && prismSessionManager.isStandaloneMode == false
                {
                    Text(
                        prismSessionManager.CurrentParkClockIsIn
                            .fullParkName()
                            + prismSessionManager.CurrentParkClockIsIn
                            .fullLocationName()
                    )
                    .font(.headline)
                    .foregroundColor(
                        Color(prismSessionManager.userColor)
                    )
                    .bold()
                    .padding(5)
                    //                    .glassBackgroundEffect(in: .rect(cornerRadius: 200))
                }
                if prismSessionManager.showBattery {
                    Text(
                        deviceBatteryLevel >= 0
                            ? Double(deviceBatteryLevel).formatted(
                                .percent.precision(.fractionLength(0))
                            ) : "—%"
                    )
                    .font(.title)
                    .foregroundStyle(prismSessionManager.userColor)
                    .padding(0)
                }
            }
            .onAppear {
                localFunfact = prismSessionManager.CurrentTeleportation
                    .randomFunfact()
                #if canImport(UIKit)
                    UIDevice.current.isBatteryMonitoringEnabled = true
                    updateBatteryLevel()
                #endif
            }
            .onChange(of: prismSessionManager.CurrentTeleportation) {
                oldValue,
                newValue in
                localFunfact = prismSessionManager.CurrentTeleportation
                    .randomFunfact()
            }
            .onChange(of: prismSessionManager.isStandaloneMode) {
                oldValue,
                newValue in
                localFunfact = prismSessionManager.CurrentTeleportation
                    .randomFunfact()
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIDevice.batteryLevelDidChangeNotification
                )
            ) { _ in
                updateBatteryLevel()
            }

            .onDisappear {
                #if canImport(UIKit)
                    UIDevice.current.isBatteryMonitoringEnabled = false
                #endif
            }
        }

        func getRandomFactFromLocal() -> String {
            if prismSessionManager.isStandaloneMode == false && prismSessionManager.currentMode == .themeParkMode {
                return prismSessionManager.CurrentParkClockIsIn.funfacts
                    .randomElement()!
            }
            
            else {
                return prismSessionManager.CurrentTeleportation.randomFunfact()
            }
        }
    }

    extension VisionClockInfoView {
        fileprivate func updateBatteryLevel() {
            #if canImport(UIKit)
                deviceBatteryLevel = UIDevice.current.batteryLevel
            #endif
        }
    }

    func VirtualTempClockColor(temp: Int) -> UIColor {
        return UIColor(.green)
    }

#endif
