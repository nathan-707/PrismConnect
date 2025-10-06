//
//  ConnectedMainMenu.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 2/28/25..
//
import FoundationModels
import SwiftUI
import WeatherKit

#if os(iOS)
let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
let notPendingImpact = UIImpactFeedbackGenerator(style: .rigid)
let lightImpact = UIImpactFeedbackGenerator(style: .light)
let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
let softImpact = UIImpactFeedbackGenerator(style: .soft)
var platform: String = ""

struct ConnectedMainMenu: View {
    @EnvironmentObject private var prismSessionManager: ClockSessionManager
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) var colorScheme // Detects light or dark mode
    
    @State private var AsistantIsShown = false
    @State private var animate = false
    @State private var currentScenePhase: ScenePhase = .active
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            if prismSessionManager.currentMode == .teleportMode || prismSessionManager.currentMode == .themeParkMode  {
                
                let startColor: Color = colorScheme == .dark ? .black : .white
                let endColor: Color = Color(cgColor: prismSessionManager.tempClockColor)
                
                LinearGradient(
                    gradient: Gradient(colors: [startColor, endColor]),
                    startPoint: .center,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            
            else if prismSessionManager.currentLightEffect == .custom_m && prismSessionManager.masterEffect != .onlyShowW {
                let startColor: Color = colorScheme == .dark ? .black : .white
                let endColor: Color = Color(cgColor: prismSessionManager.customColor)
                
                LinearGradient(
                    gradient: Gradient(colors: [startColor, endColor]),
                    startPoint: .center,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            
            
            VStack {
                if prismSessionManager.peripheralConnected || debug.testingSoDontShowSetup == true {
                    
                    TopTitleBar()
                    
                    if prismSessionManager.currentMode == .sleepMode { // show sleep options.
                        SleepModeView()
                    }
                    
                    else if prismSessionManager.currentMode == .home && !prismSessionManager.pending || debug.testingSoDontShowSetup == true { // show home options.
                        HStack{
                            VStack {
                                TeleportButton()
                                    .padding(.bottom, 5)
                                    .padding(.horizontal, 15)
                                
                                Text(prismSessionManager.cityIsSelected ? prismSessionManager.selectedTeleportCity.nameForPicker() :          prismSessionManager.selectedPark.pickerName()).bold()
                                    .foregroundColor(.green)
                                    .padding(5)
                            }
                        }
                        
                        PickEffectView()
                        
                    }
                    
                    else if prismSessionManager.currentMode == .teleportMode && !prismSessionManager.pending { // show teleport options.
                        InTeleportModeView()
                        
                        Button(String(), systemImage: "house", action: {
                            heavyImpact.impactOccurred()
                            prismSessionManager.pending = true
                            prismSessionManager.pendingMode = .home
                            prismSessionManager.sendCommand(command: .home)
                        })
                        
                        .foregroundStyle(prismSessionManager.prismboxVersion?.color ?? .accentColor)
                        .scaleEffect(2)
                        .padding()
                        
                        if #available(iOS 26, *) {

aiFunfactView()
                        }
                        
                    }
                    
                    else if prismSessionManager.currentMode == .themeParkMode && !prismSessionManager.pending { // show theme park options.
                        ThemeParkView()
                        
                        Button(String(), systemImage: "house", action: {
                            heavyImpact.impactOccurred()
                            prismSessionManager.pending = true
                            prismSessionManager.pendingMode = .home
                            prismSessionManager.sendCommand(command: .home)
                        })
                        
                        .foregroundStyle(prismSessionManager.prismboxVersion?.color ?? .accentColor)
                        .scaleEffect(2)
                        .padding()
                        
                        
                        if #available(iOS 26, *) {
                            aiFunfactView()
                        }
                        
                    }
                    
                    else {
                        ProgressView()
                            .scaleEffect(progressScale)
                        
                    }
                    
                    Spacer()
                    
                } else {
                    VStack{
                        
                        Text("Searching for PrismBox")
                            .foregroundStyle(.secondary)
                            .font(.title)
                        
                        ProgressView()
                            .scaleEffect(progressScale)
                    }
                }
            }
            .onAppear(){
                print(prismSessionManager.CurrentTeleportation.city)
                prismSessionManager.connect()
            }
        }
        
        .onChange(of: prismSessionManager.pending, { oldValue, newValue in
            if !newValue{
                notPendingImpact.impactOccurred()
            }
        })
        
        .onAppear(){
            mediumImpact.prepare()
            heavyImpact.prepare()
            notPendingImpact.prepare()
            lightImpact.prepare()
            softImpact.prepare()
        }
        
        .onChange(of: prismSessionManager.peripheralConnected, { oldValue, newValue in
            if (newValue == false){
                prismSessionManager.pendingMode = .home
                prismSessionManager.pending = false
            }
        })
        
        .onChange(of: scenePhase, { oldValue, newValue in
            currentScenePhase = newValue
            if newValue == .active {
                print("active")
                prismSessionManager.ping()
            }
            
            else if newValue == .background {
                print("background")
                prismSessionManager.disconnect()
            }
        })
        
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(timer) { _ in
            if (currentScenePhase == .active){
                if !prismSessionManager.peripheralConnected{
                    prismSessionManager.connect()
                }
            }
        }
    }
    
    
}




func setupAI() -> Bool {
    
    if #available(iOS 26, *) {
        
        let model = SystemLanguageModel.default
        
        switch model.availability {
        case .available:
            return true
            // Show your intelligence UI.
        case .unavailable(.deviceNotEligible):
            return false
            // Show an alternative UI.
        case .unavailable(.appleIntelligenceNotEnabled):
            return false
            // Ask the person to turn on Apple Intelligence.
        case .unavailable(.modelNotReady):
            return false
            // The model isn't ready because it's downloading or because of other system reasons.
        case .unavailable(_):
            return false
            // The model is unavailable for an unknown reason.
            
        }
    }
    
    return false
}


struct TopTitleBar: View {
    @EnvironmentObject private var prismSessionManager: ClockSessionManager
    @State private var settingsShown = false
    @State private var AsistantIsShown = false
    @State private var aiIsEnabled = false
    
    var body: some View {
        HStack{
            if prismSessionManager.sleepTimerOn && !prismSessionManager.pending {
                Button("", systemImage: "powersleep") {
                    heavyImpact.impactOccurred()
                    prismSessionManager.sleepTimerOn = false
                    prismSessionManager.updateSettings(nameOfSetting: "sleepTimer", value: 0)
                }
                .tint(.secondary)
            }
            
            
            if aiIsEnabled && !prismSessionManager.pending && prismSessionManager.currentMode == .home {
                Button("", systemImage: "sparkle") {
                    softImpact.impactOccurred()
                    AsistantIsShown = true
                }
                .tint(.secondary)
                .padding(.bottom, 5)
                .padding(.horizontal, 15)
            }
            
            Text(prismSessionManager.pendingMode.title())
                .font(.system(size: 50).monospaced().bold())
                .foregroundStyle(Color(.green))
                .padding()
            
            if !prismSessionManager.pending && prismSessionManager.currentMode != .sleepMode {
                Button("", systemImage: "gear") {
                    notPendingImpact.impactOccurred()
                    settingsShown = true
                }
                .tint(.secondary)
            }
        }.sheet(isPresented: $settingsShown) {
            Text("Settings").font(.title2).bold().padding(.top)
            Divider()
            ClockSettingsView()
        }
        .sheet(isPresented: $AsistantIsShown) {
            Text("Prism Assistant").font(.title2).bold().padding(.top)
            Divider()
            
            if #available(iOS 26, *) {
                AiAsistantView()
            }
        }
        .onAppear(){
            aiIsEnabled = setupAI()
        }
    }
}


struct HomeViewGradientBackground: View {
    @EnvironmentObject private var prismSessionManager: ClockSessionManager
    
    var body: some View {
        @Environment(\.colorScheme) var colorScheme // Detects light or dark mode
        let startColor: Color = Color(cgColor: prismSessionManager.tempClockColor)
        let endColor: Color = Color(cgColor: prismSessionManager.tempClockColor)
        
        LinearGradient(
            gradient: Gradient(colors: [startColor, endColor]),
            startPoint: .center,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
    }
}

#Preview {
    ConnectedMainMenu()
        .environmentObject(ClockSessionManager.init())
}
#endif



