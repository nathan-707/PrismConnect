//
//  VisionView.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 4/7/25.
//
#if os(visionOS)

import SwiftUI

struct VisionView: View {
    @EnvironmentObject private var prismSessionManager: ClockSessionManager
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @State var spaceIsOpen: Bool = false
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State var modelOn: Bool = false
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .controlPanelGuide, vertical: .bottom)) {
            ClockVolume()
            VStack{
                Spacer()

     
                ClockDisplayInfo()
                
                
                if prismSessionManager.presentSelectLocationView  {
                    TeleportOptionsQuickMenu()
                }
                

                GlobeControls()
            }
        }
    }
}


extension HorizontalAlignment {
    /// A custom alignment to center the control panel under the globe.
    private struct ControlPanelAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[HorizontalAlignment.center]
        }
    }
    
    /// A custom alignment guide to center the control panel under the globe.
    static let controlPanelGuide = HorizontalAlignment(
        ControlPanelAlignment.self
    )
}
#Preview {
    VisionView()
}
#endif

