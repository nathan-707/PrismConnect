//
//  ContentView.swift
//  bluetoothTest
//
//  Created by Nathan Eriksen on 6/13/24.
//

import CoreBluetooth
import SwiftUI

#if os(iOS)
import AccessorySetupKit
import CoreBluetooth

struct ContentView: View {
    @EnvironmentObject var prismSessionManager: ClockSessionManager
    
    var body: some View {
        
        if prismSessionManager.pickerDismissed
            && prismSessionManager.authenticated,
           prismSessionManager.prismDevice != nil
        {
            
            if prismSessionManager.status == .startSetup  {
                SetupWifiView()
            }
            
            else if prismSessionManager.status == .failedToConnectDuringSetup {
                Text("Wrong WiFi or Invalid Zip. Try Again.").foregroundStyle(.red).bold()
                SetupWifiView()
            }
            else if prismSessionManager.status == .neverConnected && prismSessionManager.deviceType != .pencil {
                Text("Follow the on-screen instructions.")
            }
            
            else if prismSessionManager.status == .verifying {
                Text("Connecting")
                ProgressView()
            }
            
            else if prismSessionManager.appView == .connectedMainMenu {
                ConnectedMainMenu()
            }
        } else {
            
            if debug.testingSoDontShowSetup {
                ConnectedMainMenu()
            } else {
                
                
                if prismSessionManager.hasConnected {
                    ManageDeviceView()
                } else {
                    makeSetupView
                }
                
                
            }
        }
    }
    
    @ViewBuilder
    private var makeSetupView: some View {
        VStack {
            Spacer()
            Image(systemName: "clock.badge.questionmark.fill")
                .font(.system(size: 150, weight: .light, design: .default))
                .foregroundStyle(.gray)
            Text("No PrismBox")
                .font(Font.title.weight(.bold))
                .padding(.vertical, 12)
            Text(
                "Make Sure Clock is Connected to Internet, Then Hold iPhone Near Clock and Proceed With Setup"
            )
            .font(.subheadline)
            .multilineTextAlignment(.center)
            
            Spacer()
            
            Button {
#if os(iOS)
                heavyImpact.impactOccurred()
                prismSessionManager.presentPicker()
#endif
                
            } label: {
                Text("Setup PrismBox")
                    .frame(maxWidth: .infinity)
                    .font(Font.headline.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle)
            .foregroundStyle(.primary)
            .controlSize(.large)
            .padding(.top, 110)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(64)
    }
}
#endif
