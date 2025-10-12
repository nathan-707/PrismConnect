//
//  ClockDisplayInfo.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 9/2/25.
//

import Foundation
import SwiftUI

#if os(visionOS)

    struct ClockDisplayInfo: View {
        @State var currentDate = Date()
        @State var clockTime: String = "1:00"
        @State private var timer: Timer? = nil
        @State var localFunfact = "sugma"
        @EnvironmentObject private var prismSessionManager: ClockSessionManager
        private var formattedTime: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm  a"  // This ensures a space before AM/PM
            return formatter.string(from: currentDate)
        }

        var body: some View {
            VStack {
                
    
                
                if prismSessionManager.initHomeWeather {
                    if prismSessionManager.isStandaloneMode == false
                        && prismSessionManager.pending
                    {
                        ProgressView() 
                    } else {
                        VisionClockInfoView()
                    }
                } else {
                    if prismSessionManager.locationDenied {
                        Text("Allow Location in Settings for Weather.")
                    } else {
                        ProgressView()

                    }
                }
            }

//            .onChange(of: prismSessionManager.clock_time_min) {
//                oldValue,
//                newValue in
//                clockTime = prismSessionManager.timeFormatted()
//            }
//            .onAppear {
//                //            localFunfact = prismSessionManager.CurrentTeleportation.funfacts.randomElement() ?? "No fun fact available"
//
//                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true)
//                { _ in
//                    currentDate = Date()
//                }
//                clockTime = prismSessionManager.timeFormatted()
//            }
            .onChange(
                of: prismSessionManager.CurrentTeleportation,
                { oldValue, newValue in
                    //            localFunfact = prismSessionManager.CurrentTeleportation.funfacts.randomElement() ?? "No fun fact available"
                }
            )
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }

    }
#endif
