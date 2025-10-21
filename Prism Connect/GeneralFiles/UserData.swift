//
//  UserData.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 9/19/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
class DataModel {

    var imperial: Bool
    var timeScale: Double
    var tempScale: Double

    var cRed: Double
    var cGreen: Double
    var cBlue: Double
    var showBattery: Bool

    var showTemperature: Bool
    var tourInterval: Int
    var soundOn: Bool
    var volume: Double

    var showFunfact: Bool

    // future proofing...
    var intIMayUse1: Int = 0
    var intIMayUse2: Int = 0
    var intIMayUse3: Int = 0
    var intIMayUse4: Int = 0
    var intIMayUse5: Int = 0

    var doubleIMayUse1: Double = 0
    var doubleIMayUse2: Double = 0
    var doubleIMayUse3: Double = 0
    var doubleIMayUse4: Double = 0
    var doubleIMayUse5: Double = 0

    var boolIMayUse1: Bool = false
    var boolIMayUse2: Bool = false
    var boolIMayUse3: Bool = false
    var boolIMayUse4: Bool = false
    var boolIMayUse5: Bool = false

    var lastKnownLat: Double = 0
    var lastKnownLong: Double = 0
    var showConnectToPrismboxButton = false
    /////////////////////////////////////////////////////////

    init() {
        self.imperial = defaultSettings.default_imperial
        self.timeScale = defaultSettings.default_timeScale
        self.tempScale = defaultSettings.default_tempScale

        self.cRed = defaultSettings.default_cRed
        self.cGreen = defaultSettings.default_cgreen
        self.cBlue = defaultSettings.default_cBlue

        self.showBattery = defaultSettings.default_showBattery
        self.showTemperature = defaultSettings.default_showTemperature
        self.soundOn = defaultSettings.default_soundON
        self.volume = defaultSettings.defaultVolume
        self.tourInterval = defaultSettings.defaultWorldTourInterval_Mins
        self.showFunfact = defaultSettings.default_showFunfact
    }
}
