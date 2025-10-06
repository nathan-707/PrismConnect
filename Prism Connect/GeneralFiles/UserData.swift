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
    
    

    init() {
        self.imperial = true
        self.timeScale = 1
        self.tempScale = 1

        self.cRed = 0
        self.cGreen = 1
        self.cBlue = 0
        
        self.showBattery = false
        self.showTemperature = true
        self.soundOn = true
        self.volume = defaultVolume
        self.tourInterval = defaultWorldTourInterval_Mins
        self.showFunfact = true
    }
}
