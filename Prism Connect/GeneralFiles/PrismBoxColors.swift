//
//  PrismBoxColors.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 2/25/25.
//


import CoreBluetooth
import SwiftUI

enum PrismBox: String {
    case Accessory, mono

    var color: Color {
        switch self {
        case .mono: .green
        case .Accessory: .green
        }
    }

    var displayName: String {
        "\(self.rawValue.capitalized)"
    }

    
    var productImageName: String {
        switch self {
        case .Accessory: "prismClock"
        case .mono: "prismClock"
        }
        
    }

    var serviceUUID: CBUUID {
        switch self {
            case .Accessory: CBUUID(string: "E56A082E-C49B-47CA-A2AB-389127B8ABE3")
            case .mono: CBUUID(string: "E58A082E-C49B-47CA-A2AB-389127B8ABE4")
        }
    }
}
