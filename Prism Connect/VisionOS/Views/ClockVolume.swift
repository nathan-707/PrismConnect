//
//  ClockVolume.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 5/30/25.
//

import RealityKit
import RealityKitContent
import SwiftUI

struct ClockVolume: View {
    @Environment(\.openWindow) private var openWindow
    // Runs whenever scenePhase changes; prior task is cancelled automatically.
    @EnvironmentObject private var prismSessionManager: ClockSessionManager
    @State var manager: WeatherVolumeManager?
    @Environment(\.scenePhase) var scenePhase: ScenePhase
    @State private var getWeatherTask: Task<Void, Never>?
    @State private var keepTryingToGetWeatherTask: Task<Void, Never>?
    @State private var updateTimeTask: Task<Void, Never>?

    var body: some View {
        RealityView { content in
            guard
                let Scene = try? await Entity(
                    named: "VolumeWeather",
                    in: realityKitContentBundle
                )
            else {
                fatalError()
            }
            manager = WeatherVolumeManager(
                Scene: Scene,
                currentWeather: prismSessionManager.clock_weather,
                isDay: prismSessionManager.isDay,
                defaultGain: prismSessionManager.rainSnowGain,
                soundOn: prismSessionManager.soundOn
            )
            content.add(Scene)
        }

        .onChange(
            of: prismSessionManager.tryToTurnOnStandAloneMode,
            { oldValue, newValue in
                print(newValue)
                if prismSessionManager.tryToTurnOnStandAloneMode {

                }
            }
        )

        .onChange(
            of: scenePhase,
            { oldValue, newValue in
                if newValue == .active {  // app active. reschedule the get time and get weather task
                    if getWeatherTask == nil
                        || ((getWeatherTask?.isCancelled) != nil)
                    {
                        getWeatherTask = getWeatherTaskSch()
                    }

                    if updateTimeTask == nil
                        || ((updateTimeTask?.isCancelled) != nil)
                    {
                        updateTimeTask = updateTimeTaskSch()
                    }
                } else {  // app not active. cancel all task.
                    getWeatherTask?.cancel()
                    //                    updateTimeTask?.cancel()
                }
            }
        )
        .onChange(of: prismSessionManager.clock_weather) { _, _ in
            manager?.updateWeather(
                weatherUpdate: prismSessionManager.clock_weather,
                isDay: prismSessionManager.isDay,
                defaultGain: prismSessionManager.rainSnowGain,
                soundOn: prismSessionManager.soundOn
            )
        }
        .onChange(of: prismSessionManager.isDay) { _, _ in
            manager?.updateWeather(
                weatherUpdate: prismSessionManager.clock_weather,
                isDay: prismSessionManager.isDay,
                defaultGain: prismSessionManager.rainSnowGain,
                soundOn: prismSessionManager.soundOn
            )
        }

        .onAppear {
            prismSessionManager.getWeather(mode: .home, city: worldTourCity)
            keepTryingToGetWeatherTask = keepTryingToGetWeatherTaskSch()
            getWeatherTask = getWeatherTaskSch()
            updateTimeTask = updateTimeTaskSch()
            initAudio()
        }
        .onChange(
            of: prismSessionManager.presentSettings,
            { _, _ in
                if prismSessionManager.presentSettings {
                    openWindow(id: "SettingsWindow")
                }
            }
        )
        .onChange(
            of: prismSessionManager.peripheralConnected,
            { oldValue, newValue in
                prismSessionManager.reportConnectionTask?.cancel()
                prismSessionManager.searchingForClock = false
            }
        )
        .onChange(of: prismSessionManager.soundOn) { oldValue, newValue in
            // todo: make this mute it
            manager?.updateAudio(
                AudioToPlay: prismSessionManager.clock_weather.audioType(
                    isDay: prismSessionManager.isDay
                ),
                soundOn: prismSessionManager.soundOn,
                defaultGain: prismSessionManager.rainSnowGain
            )
        }

        .onChange(of: prismSessionManager.rainSnowGain) { oldValue, newValue in
            manager?.updateAudioLevel(
                level: newValue,
                soundOn: prismSessionManager.soundOn
            )
        }

    }

    func updateTimeTaskSch() -> Task<Void, Never>? {
        return Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                prismSessionManager.updateTime()
            }
        }
    }

    func getWeatherTaskSch() -> Task<Void, Never>? {
        return Task {
            while !Task.isCancelled {
                guard prismSessionManager.isStandaloneMode
                else {
                    try? await Task.sleep(for: .seconds(1))
                    continue
                }

                if prismSessionManager.standalonemode_Mode == .home
                    || prismSessionManager.standalonemode_Mode == .teleportMode
                        && !prismSessionManager.worldTourIsOn
                {
                    if let last = lastHomeSuccessFetchDate {
                        let elapsed = Date().timeIntervalSince(last)
                        let interval = getWeatherInterval_Mins * 60

                        if elapsed < interval
                            && prismSessionManager.failedHome == false
                        {
                            if debug.printGetWeatherTimers {
                                print(
                                    "home or city: \(Int(elapsed)) s elapsed (< \(Int(interval)) s interval)"
                                )
                            }
                            try? await Task.sleep(for: .seconds(1))
                            continue
                        }
                    }

                    if prismSessionManager.standalonemode_Mode == .home {
                        prismSessionManager.getWeather(
                            mode: .home,
                            city: prismSessionManager.CurrentTeleportation
                        )
                    } else {
                        prismSessionManager.getWeather(
                            mode: .teleportMode,
                            city: prismSessionManager.CurrentTeleportation
                        )
                    }

                    print("called got weather. sleeping 3 seconds.(HOME MODE)")
                    try? await Task.sleep(for: .seconds(3))
                }

                // world tour selected.
                else if prismSessionManager.standalonemode_Mode == .teleportMode
                    && prismSessionManager.worldTourIsOn
                {
                    //                    print("WORLD TOUR")
                    if let last = lastWorldTourSuccessFetchDate {
                        let elapsed = Date().timeIntervalSince(last)

                        let interval =
                            prismSessionManager
                            .standalone_worldTourInterval_Mins * 60

                        if Int(elapsed) < interval
                            && prismSessionManager.failedTeleport == false
                        {

                            if debug.printGetWeatherTimers {
                                print(
                                    "worldTour: \(Int(elapsed))s elapsed (< \(interval)s interval)"
                                )
                            }

                            try? await Task.sleep(for: .seconds(1))
                            continue
                        }
                    }

                    prismSessionManager.CurrentTeleportation =
                        standAloneCities.randomElement()!

                    prismSessionManager.getWeather(
                        mode: prismSessionManager.standalonemode_Mode,
                        city: prismSessionManager.CurrentTeleportation
                    )
                    print(
                        "called got weather. sleeping 3 seconds.(WORLD TOUR MODE)"
                    )
                    try? await Task.sleep(for: .seconds(3))
                }
            }
        }
    }

    func keepTryingToGetWeatherTaskSch() -> Task<Void, Never>? {
        return Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))

                if prismSessionManager.isStandaloneMode {
                    if prismSessionManager.initHomeWeather {
                        keepTryingToGetWeatherTask?.cancel()
                        break
                    }
                    print("Retrying to get home weather...")
                    prismSessionManager.getWeather(
                        mode: .home,
                        city: prismSessionManager.CurrentTeleportation
                    )
                }
            }
        }
    }
}

var lastWorldTourSuccessFetchDate: Date? = nil
var lastHomeSuccessFetchDate: Date? = nil
var rainNoise: AudioResource?
var thunderStormNoise: AudioResource?
var snowNoise: AudioResource?

func loadLoopingResource(fileName: String) -> AudioResource {
    let resource = try! AudioFileResource.load(
        named: fileName,
        configuration: AudioFileResource.Configuration.init(
            loadingStrategy: .stream,
            shouldLoop: true,
            shouldRandomizeStartTime: false,
            normalization: .none
        )
    )
    return resource
}

func initAudio() {

    if debug.loadSounds {
        rainNoise = loadLoopingResource(fileName: "rain")
        thunderStormNoise = loadLoopingResource(fileName: "thunderstorm")
        snowNoise = loadLoopingResource(fileName: "snow")
    }

    print("audio initialized.")
}
