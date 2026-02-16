//
//  PrismBoxColors.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 2/25/25.
//

import CoreBluetooth
import SwiftUI

enum PrismDevice: String {
    case clock, pencilHolder

    var color: Color {
        switch self {
        case .clock: .green
        case .pencilHolder: .green
        }
    }

    var displayName: String {
        switch self {
        case .clock: "PrismBox"
        case .pencilHolder: "PrismHolder"
        }
    }

    var productImageName: String {
        switch self {
        case .clock: "prismClock"
        case .pencilHolder: "prismHolder"
        }

    }

    var serviceUUID: CBUUID {
        switch self {
        case .clock: CBUUID(string: "E56A082E-C49B-47CA-A2AB-389127B8ABE3")
        case .pencilHolder: CBUUID(string: "E58A082E-C49B-47CA-A2AB-389127B8ABE4")
        }
    }
}
