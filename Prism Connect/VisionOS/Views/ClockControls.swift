/*
 See the LICENSE.txt file for this sample’s licensing information.

 Abstract:
 Controls that people can use to manipulate the globe in a volume.
 */

#if os(visionOS)

    import SwiftUI
    import Foundation
    import SwiftData

    /// Controls that people can use to manipulate the globe in a volume.
    struct GlobeControls: View {
        @Environment(\.openImmersiveSpace) private var openImmersiveSpace
        @Environment(\.dismissImmersiveSpace) private var dismissImersiveSpace
        @Environment(\.modelContext) var modelContext
        @EnvironmentObject private var prismSessionManager: ClockSessionManager
        @Query var dataModelQuery: [DataModel]

        var body: some View {

            VStack(alignment: .tiltButtonGuide) {
                if prismSessionManager.searchingForClock
                    || prismSessionManager.reportConnection
                {
                    if prismSessionManager.reportConnection {
                        Text(
                            prismSessionManager.peripheralConnected
                                ? "PrismBox Connected." : "PrismBox Not Found."
                        ).padding(.vertical)
                    } else {
                        ProgressView()
                        Text("Searching for PrismBox...")
                            .padding()
                    }
                } else {
                    VStack {
                        HStack(spacing: 17) {

                            if prismSessionManager.isStandaloneMode {
                                Toggle(
                                    isOn: $prismSessionManager
                                        .presentSelectLocationView
                                ) {
                                    Label(
                                        "select location",
                                        systemImage: prismSessionManager
                                            .standalonemode_Mode == .home
                                            ? "globe" : "house"
                                    )
                                }
                            }

                            Toggle(isOn: $prismSessionManager.presentSettings) {
                                Label("settings", systemImage: "gear")
                            }

                            Toggle(
                                isOn: $prismSessionManager
                                    .tryToTurnOnStandAloneMode
                            ) {
                                Label(
                                    "NoPrismBox",
                                    systemImage: prismSessionManager
                                        .tryToTurnOnStandAloneMode
                                        ? "clock.badge.checkmark" : "clock"
                                )
                            }
                            .onChange(
                                of: prismSessionManager
                                    .tryToTurnOnStandAloneMode
                            ) {

                                print(
                                    prismSessionManager
                                        .tryToTurnOnStandAloneMode
                                        ? "Standalone: TRUE"
                                        : "Standalone: FALSE"
                                )

                                if !prismSessionManager
                                    .tryToTurnOnStandAloneMode
                                {  // get weather data over internet and present teleport options.
                                    prismSessionManager.disconnect()
                                    
                                    prismSessionManager.standalonemode_Mode = .home

                                   prismSessionManager.getWeather(
                                            mode: prismSessionManager
                                                .standalonemode_Mode,
                                            city: worldTourCity
                                        )
                                    

                                } else {
                                    prismSessionManager.connect()
                                    prismSessionManager
                                        .waitToTryToConnectAndReport()
                                }
                            }
                        }
                        .toggleStyle(.button)
                        .buttonStyle(.borderless)
                        .labelStyle(.iconOnly)
                        .padding(12)
                        .glassBackgroundEffect(in: .rect(cornerRadius: 50))
                        .alignmentGuide(.controlPanelGuide) { context in
                            context[HorizontalAlignment.center]
                        }
                        .accessibilitySortPriority(2)

                    }
                }
            }.padding(.bottom)
                .onAppear {
                    initSettings()
                }
        }

        func initColor() {
            // e.g., in SettingsView.onAppear or where you set up the session manager
            if let dm = dataModelQuery.first {
                prismSessionManager.userColor = Color(
                    red: dm.cRed,
                    green: dm.cGreen,
                    blue: dm.cBlue
                )
                print(dm)
            }
        }

        func initSettings() {

            print(dataModelQuery.count, " datamodels")

            if dataModelQuery.isEmpty {
                print("Nothing")
                modelContext.insert(DataModel())
                print(dataModelQuery.count, " datamodels")

                do {
                    try modelContext.save()
                } catch {
                    print("Error initializing settings")
                }

            } else {
                
                
//                self.imperial = true
//                self.timeScale = 1
//                self.tempScale = 1
//

//                
//                self.showBattery = false
//                self.showTemperature = true
//                self.soundOn = true
//                self.volume = -30
//                self.tourInterval = 0
                
                guard let savedDataModel = dataModelQuery.first else {return}
                print("Something")
                prismSessionManager.imperial = savedDataModel.imperial
                prismSessionManager.timeScale = savedDataModel.timeScale
                prismSessionManager.tempScale = savedDataModel.tempScale
                prismSessionManager.showBattery = savedDataModel.showBattery
                prismSessionManager.showBattery = savedDataModel.showBattery
                prismSessionManager.showTemperature = savedDataModel.showTemperature
                prismSessionManager.soundOn = savedDataModel.soundOn
                prismSessionManager.rainSnowGain = savedDataModel.volume
                prismSessionManager.standalone_worldTourInterval_Mins = savedDataModel.tourInterval
                prismSessionManager.showFunfact = savedDataModel.showFunfact
                initColor()
            }
        }
    }

    /// A custom picker for choosing a time of year.
    extension HorizontalAlignment {
        /// A custom alignment to center the tilt menu over its button.
        private struct TiltButtonAlignment: AlignmentID {
            static func defaultValue(in context: ViewDimensions) -> CGFloat {
                context[HorizontalAlignment.center]
            }
        }

        /// A custom alignment guide to center the tilt menu over its button.
        fileprivate static let tiltButtonGuide = HorizontalAlignment(
            TiltButtonAlignment.self
        )
    }

#endif
