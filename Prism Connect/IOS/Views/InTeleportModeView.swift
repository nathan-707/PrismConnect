//
//  InTeleportModeView.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 3/10/25.
//

import SwiftUI

struct InTeleportModeView: View {
    @EnvironmentObject private var prismSessionManager: ClockSessionManager
    
    var body: some View {
        
        VStack{
            Text("Welcome to").font(.headline).bold().padding(.top, 5)
            
            Text(prismSessionManager.CurrentTeleportation.city + ", " + prismSessionManager.CurrentTeleportation.territory)
                .font(.title2)
                .bold()
                .padding(.bottom, 20)
            
            teleportCityInfoView()
        }.onDisappear(){
#if os(iOS)
            softImpact.impactOccurred()
#endif
            
        }
    }
}

struct teleportCityInfoView: View {
    @EnvironmentObject private var prismSessionManager: ClockSessionManager
    var body: some View {
        VStack{
            HStack{
                Text(String(prismSessionManager.clock_temperature))
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(Color(cgColor: prismSessionManager.tempClockColor))
                    .scaleEffect(1.3)
                    .padding(.bottom,5)
                
                Text(" F")
                    .bold()
                    .foregroundStyle(Color(cgColor: prismSessionManager.tempClockColor))
                    .scaleEffect(1.3)
            }
            
            Text(String(prismSessionManager.clock_weather.title()))
                .font(.title2)
                .bold()
                .padding(.bottom,5)
                .foregroundStyle(Color(cgColor: prismSessionManager.tempClockColor))
        }
    }
}
