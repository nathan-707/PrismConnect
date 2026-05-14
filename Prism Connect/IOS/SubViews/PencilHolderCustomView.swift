//
//  PencilHolderCustomView.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 3/18/26.
//

import SwiftUI

struct PencilHolderCustomView: View {
    @EnvironmentObject var prismSessionManager: ClockSessionManager
    
    @State private var presentCreds = false
    @State private var changeWifi = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                statusSection
                actionSection
                
                if (presentCreds && prismSessionManager.status != .connected) || changeWifi {
                    SetupWifiView(onDone: {
                        // After sending creds, collapse the setup and reset change flag
                        presentCreds = false
                        changeWifi = false
                    })
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding()
        }
        .onAppear {
            prismSessionManager.ping()
        }
        .animation(.default, value: prismSessionManager.status)
        .animation(.default, value: presentCreds)
        .animation(.default, value: changeWifi)
    }
    
    private var header: some View {
        VStack(spacing: 4) {
            Text("Pencil Holder")
                .font(.title2).bold()
            if prismSessionManager.pencilClock_internet_enabled {
                Text("Internet features are available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Connect to Wi‑Fi to enable weather and scheduling features.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var statusSection: some View {
        Group {
            switch prismSessionManager.status {
            case .connected:
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("Connected to internet.").bold()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if !prismSessionManager.location.isEmpty {
                    Text("Showing weather for \(prismSessionManager.location)")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            case .connecting:
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Connecting to internet...").bold()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            case .failedToConnectDuringSetup:
                Label("Wrong password or SSID", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
            default:
                EmptyView()
            }
        }
    }
    
    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if prismSessionManager.pencilClock_internet_enabled {
                if changeWifi == false {
                    Button {
                        prismSessionManager.updateSettings(nameOfSetting: "startWifiSetup", value: 1)
                        changeWifi = true
                    } label: {
                        Label("Change Wi‑Fi", systemImage: "wifi")
                    }
                }
            }
            
            switch prismSessionManager.status {
            case .connected:
                EmptyView()
                Button(role: .destructive) {
                    prismSessionManager.updateSettings(
                        nameOfSetting: "clearPencil",
                        value: "ssid"
                    )
                } label: {
                    Label("Erase Wi‑Fi", systemImage: "trash")
                }
            case .connecting:
                EmptyView()
            default:
                VStack(alignment: .leading, spacing: 8) {
                    
                    if prismSessionManager.pencilClock_internet_enabled == false {
                        
                        
                        Button {
                            prismSessionManager.updateSettings(nameOfSetting: "startWifiSetup", value: 1)
                            presentCreds = true
                        } label: {
                            Label("Set up Wi‑Fi", systemImage: "wifi")
                        }
                        Text("Connect to Wi‑Fi to enable light modes that shine the outside weather conditions and schedule on/off times.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                    
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    PencilHolderCustomView()
}

struct SetupWifiView: View {
    @EnvironmentObject var prismSessionManager: ClockSessionManager
    @State private var ssid = ""
    @State private var password = ""
    @State private var zipcode = ""
    @State private var currentScenePhase: ScenePhase = .active
    
    // Add a state variable to track the cancelling progress
    @State private var isCancelling = false

    let timer = Timer.publish(every: 0.1, on: .main, in: .common)
        .autoconnect()
    
    var onDone: (() -> Void)? = nil
    
    private var isZipValid: Bool {
        zipcode.trimmingCharacters(in: .whitespaces).range(of: "^\\d{5}$", options: .regularExpression) != nil
    }
    private var canSubmit: Bool {
        !ssid.trimmingCharacters(in: .whitespaces).isEmpty && isZipValid
    }
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Wi‑Fi Setup").font(.title3).bold()
                Text("Enter your network details to connect and enable weather features.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 12) {
                LabeledContent {
                    TextField("Network name", text: $ssid)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .textContentType(.username)
                        .submitLabel(.next)
                        .onSubmit { focusNext() }
                } label: {
                    Label("SSID", systemImage: "wifi")
                }
                
                LabeledContent {
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                        .submitLabel(.next)
                        .onSubmit { focusNext() }
                } label: {
                    Label("Password", systemImage: "lock.fill")
                }
                
                LabeledContent {
                    TextField("5‑digit ZIP", text: $zipcode)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .textContentType(.postalCode)
                        .submitLabel(.go)
                        .onSubmit { sendCreds() }
                } label: {
                    Label("ZIP Code", systemImage: "mappin.and.ellipse")
                }
                if !zipcode.isEmpty && !isZipValid {
                    Text("ZIP code must be 5 digits.")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            HStack {
                // Toggle between ProgressView and the Cancel Button
                if isCancelling {
                    ProgressView()
                        .padding(.horizontal, 16) // Added padding to maintain similar visual spacing
                } else {
                    Button("Cancel") {
                        isCancelling = true
                        
                        prismSessionManager.updateSettings(
                            nameOfSetting: "cancelSet",
                            value: password
                        )
                        
                        // Wait for 5 seconds and then show the button again
                        Task {
                            try? await Task.sleep(nanoseconds: 5_000_000_000)
                            isCancelling = false
                        }
                    }
                    .buttonStyle(.borderless)
                }
                
                Spacer()
                
                Button {
                    sendCreds()
                    onDone?()
                } label: {
                    Label("Save & Connect", systemImage: "arrow.forward.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
        
        .onReceive(timer) { _ in
            if currentScenePhase == .active {
                if !prismSessionManager.peripheralConnected {
                    prismSessionManager.connect()
                }
            }
        }
        
        
    }
    
    private func focusNext() {
        // Placeholder for focus handling if focus state is added later
    }
    
    private func sendCreds(){
        let trimmedSSID = ssid.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedZip = zipcode.trimmingCharacters(in: .whitespacesAndNewlines)
        
        prismSessionManager.updateSettings(nameOfSetting: "startWifiSetup", value: 1)
        
        print("ssid submitted: \(trimmedSSID)")
        prismSessionManager.updateSettings(
            nameOfSetting: "ssid",
            value: trimmedSSID
        )
        
        print("Password submitted: \(password)")
        prismSessionManager.updateSettings(
            nameOfSetting: "password",
            value: password
        )
        
        print("zipcode submitted: \(trimmedZip)")
        prismSessionManager.updateSettings(
            nameOfSetting: "zipcode",
            value: trimmedZip
        )
    }
}
