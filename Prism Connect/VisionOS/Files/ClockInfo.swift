//
//  ClockInfo.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 4/8/25.
//

import Foundation

struct VisionInfo: Codable, Equatable {
    var am: Bool
    var isDay: Bool
    var visionP: Int
    var city: Int  // current teleport city selected.
    var park: Int  // current park selected.
    var mode: Int  // home, teleport, city
    var timeHour: Int
    var timeMin: Int
    var weekDay: Int
    var DOM: Int
    var month: Int
    var weather: Int
    var temp: Int
    var tempR: Int
    var tempG: Int
    var tempB: Int
}
