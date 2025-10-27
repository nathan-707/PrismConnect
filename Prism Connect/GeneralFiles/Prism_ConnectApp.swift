//
//  Prism_ConnectApp.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 6/14/24.
//

import SwiftData
import SwiftUI

@main
struct Prism_ConnectApp: App {
    @State var prismSessionManager = ClockSessionManager()
    @State var storeModel = Store()
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.openWindow) var openWindow

    #if os(visionOS)
        var body: some Scene {
            WindowGroup(id: "SettingsWindow") {
                SettingsView()
                    .environmentObject(prismSessionManager)
                    .environmentObject(storeModel)

            }
            .modelContainer(for: [DataModel.self])
            .windowStyle(.plain)
            .defaultSize(width: 900, height: 1000)
            .windowResizability(.contentSize)
            .defaultWindowPlacement { content, context in
                if let contentWindow = context.windows.first(
                    where: { $0.id == "VisionView" })
                {
                    WindowPlacement(.trailing(contentWindow))
                } else {
                    WindowPlacement()
                }
            }

            WindowGroup(id: "SelectLocationWindow") {
                SelectLocationView()
                    .environmentObject(prismSessionManager)
                    .environmentObject(storeModel)

            }
            .modelContainer(for: [DataModel.self])
            .windowStyle(.plain)
            .defaultSize(width: 900, height: 600)
            .windowResizability(.contentSize)
            .defaultWindowPlacement { content, context in
                if let contentWindow = context.windows.first(
                    where: { $0.id == "VisionView" })
                {
                    WindowPlacement(.leading(contentWindow))
                } else {
                    WindowPlacement()
                }
            }

            WindowGroup(id: "VisionView") {
                VisionView()
                    .environmentObject(prismSessionManager)
                    .environmentObject(storeModel)

            }
            .modelContainer(for: [DataModel.self])
            .windowStyle(.volumetric)
            .defaultSize(
                width: defaultSettings.defaultVolumeWidth,
                height: defaultSettings.defaultVolumeHeight
            )

            .onChange(of: scenePhase) { oldValue, newValue in
                switch newValue {
                case .background:
                    prismSessionManager.disconnect()
                    print("background")
                case .inactive:
                    prismSessionManager.disconnect()
                    print("inactive")
                case .active:
                    prismSessionManager.connect()

                    #if os(visionOS)
                        if prismSessionManager.isShowingWeatherSpace == false {
                            openWindow(id: "VisionView")
                        }
                    #endif

                    break
                @unknown default:
                    prismSessionManager.disconnect()

                }
            }

            ImmersiveSpace(id: "ClockSpace") {
                ClockSpace()
                    .environmentObject(prismSessionManager)

                    .onAppear {
                        prismSessionManager.showingFullTrackingSpace = true
                    }

                    .onDisappear {
                        prismSessionManager.showingFullTrackingSpace = false
                        //                    openWindow(id: "VisionView")
                    }

            }
        }
    #endif

    #if os(iOS)
        var body: some Scene {
            WindowGroup {
                ContentView()
                    .environmentObject(prismSessionManager)
            }
        }
    #endif

}
