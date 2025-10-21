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

                                    prismSessionManager.standalonemode_Mode =
                                        .home

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

                            if prismSessionManager.showConnectToPrismboxButton {
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
                print("No data model in memory. settings defaults")
                modelContext.insert(DataModel())
                print(dataModelQuery.count, " datamodels")

                do {
                    try modelContext.save()
                } catch {
                    print("Error initializing settings")
                }

                // no data model. set default settings instead.
                prismSessionManager.showConnectToPrismboxButton =
                    defaultSettings.default_showConnectToPrismboxButton
                prismSessionManager.imperial = defaultSettings.default_imperial
                prismSessionManager.timeScale =
                    defaultSettings.default_timeScale
                prismSessionManager.tempScale =
                    defaultSettings.default_tempScale
                prismSessionManager.showBattery =
                    defaultSettings.default_showBattery
                prismSessionManager.showBattery =
                    defaultSettings.default_showBattery
                prismSessionManager.showTemperature =
                    defaultSettings.default_showTemperature
                prismSessionManager.soundOn = defaultSettings.default_soundON
                prismSessionManager.rainSnowGain = defaultSettings.defaultVolume
                prismSessionManager.standalone_worldTourInterval_Mins =
                    defaultSettings.defaultWorldTourInterval_Mins
                prismSessionManager.showFunfact =
                    defaultSettings.default_showFunfact
                initColor()

            } else {

                guard let savedDataModel = dataModelQuery.first else { return }
                print("Data model found. restoring settings.")
                prismSessionManager.lastKnownLat = savedDataModel.lastKnownLat
                prismSessionManager.lastKnownLong = savedDataModel.lastKnownLong
                print(
                    prismSessionManager.lastKnownLat,
                    prismSessionManager.lastKnownLong
                )
                prismSessionManager.imperial = savedDataModel.imperial
                prismSessionManager.timeScale = savedDataModel.timeScale
                prismSessionManager.tempScale = savedDataModel.tempScale
                prismSessionManager.showBattery = savedDataModel.showBattery
                prismSessionManager.showBattery = savedDataModel.showBattery
                prismSessionManager.showTemperature =
                    savedDataModel.showTemperature
                prismSessionManager.soundOn = savedDataModel.soundOn
                prismSessionManager.rainSnowGain = savedDataModel.volume
                prismSessionManager.standalone_worldTourInterval_Mins =
                    savedDataModel.tourInterval
                prismSessionManager.showFunfact = savedDataModel.showFunfact
                prismSessionManager.showConnectToPrismboxButton =
                    savedDataModel.showConnectToPrismboxButton
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
