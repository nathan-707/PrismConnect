//
//  Debug.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 7/20/25.
//

import Foundation

let progressScale = 1.33

struct Debug {
    let allowUpdateFromSettings = false

    let testingSoDontShowSetup = false
    let skipClockSearch = false
    let printStateUpdates = false

    let loadSounds = true
    let printGetWeatherTimers = false
    
    ////////////////////////////////////////////////////////////////////////////

    
    let locationDenied_Test = false
    let noInternet_Test = false
}

let debug = Debug()
