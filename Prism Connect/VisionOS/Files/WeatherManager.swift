////
////  WeatherManager.swift
////  Prism Connect
////
////  Created by Nathan Eriksen on 4/9/25.
////
//

enum WeatherLight: Int {
    case CLEAR_DAY,
        CLEAR_NIGHT,
        CLOUDS_DAY,
        CLOUDS_NIGHT,
        RAIN,
        DRIZZLE,
        THUNDERSTORM,
        SNOW,
        TORNADO,
        DUST,
        MIST,
        SMOKE,
        UNKNOWN

    static func from(_ rawValue: Int) -> WeatherLight? {
        return WeatherLight(rawValue: rawValue)
    }

    func title() -> String {
        switch self {
        case .CLEAR_DAY:
            return "Sunny"
        case .CLEAR_NIGHT:
            return "Clear Sky"
        case .CLOUDS_DAY, .CLOUDS_NIGHT:
            return "Cloudy"
        case .RAIN:
            return "Rain"
        case .DRIZZLE:
            return "Drizzle"
        case .THUNDERSTORM:
            return "T-Storms"
        case .SNOW:
            return "Snow"
        case .TORNADO:
            return "Tornado"
        case .DUST:
            return "Dust"
        case .MIST:
            return "Mist"
        case .SMOKE:
            return "Smoke"
        case .UNKNOWN:
            return ""
        }
    }

    func audioType(isDay: Bool) -> AudioType {
        switch self {
        case .CLEAR_DAY:
            return .day
        case .CLEAR_NIGHT:
            return .night
        case .CLOUDS_DAY:
            return .day
        case .CLOUDS_NIGHT:
            return .night
        case .RAIN:
            return .rain
        case .DRIZZLE:
            return .drizzle
        case .THUNDERSTORM:
            return .thunderstorm
        case .SNOW:
            return .snow
        case .TORNADO:
            return .rain
        default:
            if isDay {
                return .day
            } else {
                return .night
            }

        }
    }
}

enum AudioType {
    case rain, drizzle, thunderstorm, day, night, snow, nothing
}

func determineWeatherLight(
    weatherMain: String,
    cloudCover: Double,
    precipitationIntensity: Double,
    daytime: Bool,
    heavySnow: Double = 0.8,
    snowShower: Double = 0.3,
    heavyRain: Double = 0.8,
    rainShower: Double = 0.3
) -> (WeatherLight, String) {

    let lowerMain = weatherMain.lowercased()
    var description = ""
    var light: WeatherLight = .UNKNOWN

    if lowerMain.contains("cloud") {
        if cloudCover > 0.9 {
            description = "Overcast"
        } else if cloudCover > 0.5 {
            description = "Mostly Cloudy"
        } else {
            description = "Scattered Clouds"
        }
        light = daytime ? .CLOUDS_DAY : .CLOUDS_NIGHT
    } else if lowerMain.contains("smoke") {
        description = "Smoke"
        light = .SMOKE
    } else if lowerMain.contains("ash") {
        description = "Ash"
        light = .SMOKE
    } else if lowerMain.contains("clear") {
        if daytime {
            description = "Clear and Sunny"
            light = .CLEAR_DAY
        } else {
            description = "Clear Sky"
            light = .CLEAR_NIGHT
        }
    } else if lowerMain.contains("snow") {
        light = .SNOW
        if precipitationIntensity >= heavySnow {
            description = "Heavy Snow"
        } else if precipitationIntensity > snowShower {
            description = "Snow Shower"
        } else {
            description = "Light Snow"
        }
    } else if lowerMain.contains("rain") {
        light = .RAIN
        if precipitationIntensity > heavyRain {
            description = "Heavy Rain"
        } else if precipitationIntensity > rainShower {
            description = "Rain Showers"
        } else {
            description = "Light Rain"
        }
    } else if lowerMain.contains("tornado") {
        description = "TORNADO"
        light = .TORNADO
    } else if lowerMain.contains("drizzle") {
        description = "Drizzle"
        light = .DRIZZLE
    } else if lowerMain.contains("thunderstorm") {
        description = "Thunderstorm"
        light = .THUNDERSTORM
    } else if lowerMain.contains("mist") {
        description = "Mist"
        light = .MIST
    } else if lowerMain.contains("fog") {
        description = "Fog"
        light = .MIST
    } else if lowerMain.contains("haze") {
        description = "Haze"
        light = .MIST
    } else if lowerMain.contains("dust") {
        description = "Dust"
        light = .DUST
    } else if lowerMain.contains("wind") {
        if cloudCover > 0.15 {
            description = "Wind and Clouds"
            light = daytime ? .CLOUDS_DAY : .CLOUDS_NIGHT
        } else {
            description = "Wind and Clear"
            light = daytime ? .CLEAR_DAY : .CLEAR_NIGHT
        }
    }

    return (light, description)
}

#if os(visionOS)

    import Foundation
    import RealityKit
    import ARKit

    class WeatherManager {
        var anchorRoot = Entity()
        var clock: Entity
        var weatherTransitionPoof: Entity
        var timeEntity: Entity
        var screenBlock: Entity
        var sun: Entity
        var clouds: Entity
        var rain: Entity
        var dark_Clouds: Entity
        var moon: Entity
        var drizzle: Entity
        var clouds_fullRoom: Entity

        #if os(visionOS)
            var sceneReconstruction: MeshAnchorGenerator!
        #endif

        init(
            scene: Entity,
            weather: WeatherLight,
            hour: Int,
            min: Int,
            wholeRoom: Bool
        ) {
            self.clock = scene.findEntity(named: "Clock")!
            self.clouds = scene.findEntity(named: "CLOUDS")!
            self.sun = scene.findEntity(named: "SUN")!
            self.weatherTransitionPoof = scene.findEntity(
                named: "weatherTransitionPoof"
            )!
            self.rain = scene.findEntity(named: "RAIN")!
            self.dark_Clouds = scene.findEntity(named: "DARK_CLOUDS")!
            self.moon = scene.findEntity(named: "MOON")!
            self.drizzle = scene.findEntity(named: "DRIZZLE")!
            self.screenBlock = Entity()
            self.clouds_fullRoom = scene.findEntity(named: "CLOUDS_1")!
            self.timeEntity = ModelEntity(
                mesh: .generateText("spank me"),
                materials: [UnlitMaterial(color: .green)]
            )
            self.updateWeather(weatherUpdate: weather, wholeRoom: wholeRoom)
            self.updateTime(hour: String(hour), min: String(min))
            self.sceneReconstruction = MeshAnchorGenerator(root: anchorRoot)
        }

        func updateTime(hour: String, min: String) {
            timeEntity.removeFromParent()
            self.timeEntity = ModelEntity(
                mesh: .generateText(hour + ":" + min),
                materials: [UnlitMaterial(color: .green)]
            )
            timeEntity.scale = [0.005, 0.005, 0.005]
            timeEntity.position.x += 0.0
            timeEntity.position.y += 0
            timeEntity.position.z += 0.05
            self.clock.addChild(timeEntity)
        }

        func updateWeather(weatherUpdate: WeatherLight, wholeRoom: Bool) {

            print(weatherUpdate)

            for child in clock.children {
                if child != timeEntity && child != screenBlock {
                    clock.removeChild(child)
                }
            }

            clock.addChild(weatherTransitionPoof)

            switch weatherUpdate {
            case .CLEAR_DAY:
                clock.addChild(self.sun.clone(recursive: true))
            case .CLEAR_NIGHT:
                clock.addChild(self.moon.clone(recursive: true))
                break
            case .CLOUDS_DAY:
                clock.addChild(self.clouds.clone(recursive: true))
                clock.addChild(self.sun.clone(recursive: true))
            case .CLOUDS_NIGHT:
                clock.addChild(self.clouds.clone(recursive: true))
                clock.addChild(self.moon.clone(recursive: true))
                break
            case .RAIN:
                clock.addChild(self.rain.clone(recursive: true))
                clock.addChild(self.dark_Clouds.clone(recursive: true))
                break
            case .DRIZZLE:
                clock.addChild(self.drizzle.clone(recursive: true))
                clock.addChild(self.dark_Clouds.clone(recursive: true))
                break
            case .THUNDERSTORM:
                clock.addChild(self.dark_Clouds.clone(recursive: true))
                clock.addChild(self.rain.clone(recursive: true))
                break
            case .SNOW:
                // add here
                break
            case .TORNADO:
                // add here
                break
            case .DUST:
                // add here
                break
            case .MIST:
                // add here
                break
            case .SMOKE:
                // add here
                break
            case .UNKNOWN:
                break
            }

            if wholeRoom {
                switch weatherUpdate {
                case .CLEAR_DAY:
                    break
                case .CLEAR_NIGHT:
                    break
                case .CLOUDS_DAY:
                    self.clock.addChild(
                        self.clouds_fullRoom.clone(recursive: true)
                    )
                    break
                case .CLOUDS_NIGHT:
                    self.clock.addChild(
                        self.clouds_fullRoom.clone(recursive: true)
                    )
                    break
                case .RAIN:
                    break
                case .DRIZZLE:
                    break
                case .THUNDERSTORM:
                    break
                case .SNOW:
                    break
                case .TORNADO:
                    break
                case .DUST:
                    break
                case .MIST:
                    break
                case .SMOKE:
                    break
                case .UNKNOWN:
                    break
                }
            }
        }
    }

#endif
