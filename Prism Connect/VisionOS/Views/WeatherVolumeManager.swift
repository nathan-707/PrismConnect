//
//  WeatherVolumeManager.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 5/30/25.
//

import Foundation
import RealityKit
import Combine

struct WeatherVolumeManager {
    
    private var ScoredFlashBlinkCancellable: AnyCancellable? // Declare it as optional first
    var isDay: Bool
    var root = Entity()
    var weatherTransitionPoof: Entity
    var sun: Entity
    var clouds: Entity
    var rain: Entity
    var dark_Clouds: Entity
    var moon: Entity
    var drizzle: Entity
    var stars: Entity
    var snow: Entity
    var thunderStrike: Entity
    var thunderFlashLight: Entity
    
    var channelAudioEntity: Entity
    var lastAudio: AudioType = .nothing
    
    
    func updateAudioLevel(level: Double, soundOn: Bool) {
        if soundOn == false {
            channelAudioEntity.stopAllAudio()
            return;
        }
        channelAudioEntity.spatialAudio?.gain = level
    }
    
    func updateAudio(AudioToPlay: AudioType, soundOn: Bool, defaultGain: Double){
        
        if soundOn == false || debug.loadSounds == false {
            channelAudioEntity.stopAllAudio()
            return
        }
        
        channelAudioEntity.spatialAudio?.gain = defaultGain
            
        switch AudioToPlay {
        case .rain:
            channelAudioEntity.playAudio(rainNoise!)
        case .drizzle:
            channelAudioEntity.playAudio(rainNoise!)
        case .thunderstorm:
            channelAudioEntity.playAudio(thunderStormNoise!)
        case .snow:
            channelAudioEntity.playAudio(snowNoise!)
        default:
            channelAudioEntity.stopAllAudio()
        }
    }
    
    func updateWeather(weatherUpdate: WeatherLight, isDay: Bool, defaultGain: Double, soundOn: Bool){
        
        root.children.removeAll()
        
//        let weatherUpdate: WeatherLight = .RAIN
        
        if weatherUpdate.audioType(isDay: isDay) != lastAudio && weatherUpdate != .UNKNOWN{
            updateAudio(AudioToPlay: weatherUpdate.audioType(isDay: isDay), soundOn: soundOn, defaultGain: defaultGain)
        }
        
        switch weatherUpdate {
        case .CLEAR_DAY:
            root.addChild(sun.clone(recursive: true))
        case .CLEAR_NIGHT:
            root.addChild(moon.clone(recursive: true))
            root.addChild(stars.clone(recursive: true))
        case .CLOUDS_DAY:
            root.addChild(sun.clone(recursive: true))
            root.addChild(clouds.clone(recursive: true))
        case .CLOUDS_NIGHT:
            root.addChild(clouds.clone(recursive: true))
            root.addChild(moon.clone(recursive: true))
            putStarsAboveClouds()
        case .RAIN:
            root.addChild(rain.clone(recursive: true))
            root.addChild(dark_Clouds.clone(recursive: true))
            if isDay == false {
                putStarsAboveClouds()
            }
        case .DRIZZLE:
            root.addChild(clouds.clone(recursive: true))
            root.addChild(drizzle.clone(recursive: true))
            if isDay == false {
                putStarsAboveClouds()
            }
        case .THUNDERSTORM:
            root.addChild(rain.clone(recursive: true))
            root.addChild(dark_Clouds.clone(recursive: true))
            root.addChild(thunderStrike.clone(recursive: true))
            if isDay == false {
                putStarsAboveClouds()
            }
        case .SNOW:
            root.addChild(clouds.clone(recursive: true))
            root.addChild(snow.clone(recursive: true))
            if isDay == false {
                putStarsAboveClouds()
            }
        case .TORNADO:
            break
        case .DUST:
            root.addChild(clouds.clone(recursive: true))
        case .MIST:
            root.addChild(clouds.clone(recursive: true))
        case .SMOKE:
            root.addChild(clouds.clone(recursive: true))
        case .UNKNOWN:
            break
        }
    }
    
    init (Scene: Entity, currentWeather: WeatherLight, isDay: Bool, defaultGain: Double, soundOn: Bool) {
        self.weatherTransitionPoof = Scene.findEntity(named: "weatherTransitionPoof")!
        self.sun = Scene.findEntity(named: "SUN")!
        self.clouds = Scene.findEntity(named: "CLOUDS")!
        self.rain = Scene.findEntity(named: "RAIN")!
        self.dark_Clouds = Scene.findEntity(named: "DARK_CLOUDS")!
        self.moon = Scene.findEntity(named: "MOON")!
        self.drizzle = Scene.findEntity(named: "DRIZZLE")!
        self.stars = Scene.findEntity(named: "stars_24")!
        self.snow = Scene.findEntity(named: "snow")!
        self.thunderFlashLight = Scene.findEntity(named: "lightningSpotLight")!
        self.thunderStrike = Scene.findEntity(named: "Lightning")!.clone(recursive: true)
        self.channelAudioEntity = Entity()
        self.channelAudioEntity.components.set(SpatialAudioComponent())
        self.isDay = isDay
        Scene.children.removeAll()
        Scene.addChild(root)
        Scene.addChild(channelAudioEntity)
        self.updateWeather(weatherUpdate: currentWeather, isDay: isDay, defaultGain: defaultGain, soundOn: soundOn)
    }
    
    func putStarsAboveClouds(){
        let starClouds = stars.clone(recursive: true)
        root.addChild(starClouds)
        starClouds.position.y += 1.3
    }
}
