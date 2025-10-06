//
//  SettingsModel.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 2/25/25.
//

import SwiftUI

// MARK: - Enums (Codable)


enum Modes: Int, Codable {
    
    func title() -> String {
        switch self {
        case .home:
            return "HOME"
        case .teleportMode:
            return "TELEPORT"
        case .themeParkMode:
            return "THEMEPARK"
        case .sleepMode:
            return "SLEEPING"
        }
    }
    
    case home,
         teleportMode,
         themeParkMode,
         sleepMode
}

enum MasterEffect: Int, Codable {
    case fullEff,
         showW,
         onlyShowW
}

enum LightEffects: Int, Codable {
    case custom_m,
         dualmode_m,
         rainbowmode_m,
         headless_m,
         meteorshower_m,
         colorclock_m,
         tempclock_m,
         firemode_m
}

// MARK: - Data Struct for Serialization

enum Command: Int, Codable {
    case updateEffect,
         updateMode,
         updateLayout,
         ping
}


// MARK: - Settings Model
struct ClockSettings: Codable, Equatable {
    
    var e1: Int
    var e2: Int
    var e3: Int
    
    
    var weather: Int
    var temp: Int
    var hour: Int
    var min: Int
    var am: Bool
    var isDay: Bool
    var ignoreAlert: Int
    var disAB: Int
    var ver: Int
    var layout: Int
    var effect: Int
    var masterEffect: Int
    var mode: Int
    var pending: Int
    var getTimeInTel:Int
    var muted: Int
    var SpecFS: Float
    var HeadFS: Float
    var SCFS: Float
    var FireFS: Float
    var smallMode: Int
    var largeMode: Int
    var cR: customRed
    var cG: customGreen
    var cB: customBlue
    var tempR: Int
    var tempG: Int
    var tempB: Int
    var park: Int // current park selected.
    var telIn: teleportInterval
    var city: Int // current teleport city selected.
    var onT: onTime
    var offT: offTime
    var autoOff: Int
    var semi: semiAutomatic
    var br: brightness
    var aBr: autoBrightnessOn
    var sTi: sleepTimer
    var sTon: Int // sleep timer is on bool.
}





typealias teleportInterval = Int

typealias customRed = Int
typealias customGreen = Int
typealias customBlue = Int

typealias onTime = Int
typealias offTime = Int
typealias semiAutomatic = Int

typealias brightness = Float
typealias autoBrightnessOn = Int
typealias sleepTimer = Int

