//
//  Defaults.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 10/3/25.
//
import SwiftUI

let defaultSettings = DefaultSettings()

struct DefaultSettings {
    let getWeatherInterval_Mins: Double = 20  // home refresh interval in mins.
    let defaultWorldTourInterval_Mins = 15 // default tour interval between cities.
    let defaultVolume: Double = -20  // testing////////////////////////////////// -23.157894736842106  gain

    // default size of volume.
    let defaultVolumeWidth: CGFloat = 1800
    let defaultVolumeHeight: CGFloat = 2000

    let default_imperial = true
    let default_timeScale: Double = 2.45
    let default_tempScale: Double = 1.75

    let default_cRed: Double = 0
    let default_cgreen: Double = 1
    let default_cBlue: Double = 0

    let default_showBattery = false
    let default_showTemperature = true
    let default_soundON: Bool = true
    let default_showFunfact: Bool = true

    let default_showConnectToPrismboxButton = false

}
