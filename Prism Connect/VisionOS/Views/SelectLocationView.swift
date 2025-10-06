//
//  SelectLocationView.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 9/4/25.
//

import SwiftUI

#if os(visionOS)

    struct SelectLocationView: View {
        @Environment(\.scenePhase) private var scenePhase
        @Environment(\.dismissWindow) private var dismissWindow
        @EnvironmentObject private var prismSessionManager: ClockSessionManager
        @State var selectedCity: City = worldTourCity

        var body: some View {
            VStack {

                List {
                    ForEach(ALL_CITIES) { city in
                
                        Button(city.nameForPicker()) {
                            prismSessionManager.worldTourIsOn = false
                            selectedCity = city
                            prismSessionManager.CurrentTeleportation =
                                selectedCity
                            prismSessionManager
                                .presentSelectLocationView = false
                            prismSessionManager.standalonemode_Mode =
                                .teleportMode

                            prismSessionManager.getWeather(
                                mode: .teleportMode,
                                city: city
                            )

                        }
                        .foregroundStyle(prismSessionManager.userColor)

                    }
                }
                .padding(.top)

            }
            .glassBackgroundEffect()

            .onChange(
                of: prismSessionManager.presentSelectLocationView,
                { oldValue, newValue in
                    if !newValue {
                        dismissWindow()
                    }
                }
            )

            .onChange(of: scenePhase) { oldValue, newValue in
                prismSessionManager.presentSelectLocationView = false
            }
        }
    }
#endif
