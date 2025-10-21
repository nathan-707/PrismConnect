//
//  TeleportOptionsQuickMenu.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 9/30/25.
//

import SwiftUI

struct TeleportOptionsQuickMenu: View {
    @EnvironmentObject private var prismSessionManager: ClockSessionManager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack {
            if prismSessionManager.standalonemode_Mode == .teleportMode {
                Button {
                    prismSessionManager.standalonemode_Mode = .home
                    prismSessionManager.presentSelectLocationView = false

                    prismSessionManager.getWeather(
                        mode: .home,
                        city: worldTourCity
                    )
                } label: {
                    Text("GO HOME")
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .foregroundStyle(.white)
                .padding(12)

            } else {
                Button(
                    "Start Tour (Random City Every \(prismSessionManager.standalone_worldTourInterval_Mins) min)",
                    systemImage: "globe.americas.fill"
                ) {

                    prismSessionManager.weatherRequestIsPending = true

                    prismSessionManager
                        .presentSelectLocationView = false

                    prismSessionManager.standalonemode_Mode =
                        .teleportMode

                    prismSessionManager.worldTourIsOn = true
                    lastWorldTourSuccessFetchDate = Date(
                        timeIntervalSince1970: 0
                    )
                    getWeatherTask?.cancel()
                    getWeatherTask = getWeatherTaskSch(
                        prismSessionManager: prismSessionManager
                    )
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .foregroundStyle(.white)
                .padding(12)

                Button {
                    openWindow(id: "SelectLocationWindow")

                } label: {
                    Text("Select City")
                }
                .padding()
            }
        }
    }
}

#Preview {
    TeleportOptionsQuickMenu()
}
