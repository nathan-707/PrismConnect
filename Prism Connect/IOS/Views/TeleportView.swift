//
//  TeleportView.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 3/5/25.
//

import SwiftUI

#if os(iOS)

    struct TeleportButton: View {
        @EnvironmentObject private var prismSessionManager: ClockSessionManager
        @State private var telePicker = false

        var body: some View {
            HStack {
                Button("TELEPORT", systemImage: "globe.americas.fill") {
                    heavyImpact.impactOccurred()
                    prismSessionManager.pending = true

                    if prismSessionManager.cityIsSelected {
                        prismSessionManager.pendingMode = .teleportMode
                        prismSessionManager.sendCommand(command: .teleportMode)
                    } else {
                        prismSessionManager.pending = true
                        prismSessionManager.pendingMode = .themeParkMode
                        prismSessionManager.sendCommand(command: .themeParkMode)
                    }
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)

                Button {
                    mediumImpact.impactOccurred()
                    telePicker = true
                } label: {
                    Image(systemName: "slider.horizontal.2.square")
                        .foregroundStyle(.green)
                        .scaleEffect(1.5)
                }
                .padding(.horizontal, 5)
            }

            .sheet(isPresented: $telePicker) {

                Text("Select Location").font(.title).bold().padding(.top)
                Divider()

                Text(
                    prismSessionManager.cityIsSelected
                        ? prismSessionManager.selectedTeleportCity
                            .nameForPicker()
                        : prismSessionManager.selectedPark.pickerName()
                )
                .bold()
                .padding()

                List {
                    ForEach(ALL_CITIES) { city in
                        Button(city.nameForPicker()) {
                            notPendingImpact.impactOccurred()
                            prismSessionManager.selectedTeleportCity = city
                            telePicker = false
                            prismSessionManager.cityIsSelected = true
                        }
                        .foregroundStyle(.green)
                    }

                    Text("Theme Park Wait Times")
                        .foregroundStyle(.secondary)
                        .font(.headline)

                    ForEach(AllParks) { park in
                        Button(
                            park.fullParkName() + ", " + park.fullLocationName()
                        ) {
                            prismSessionManager.selectedPark = park
                            telePicker = false
                            prismSessionManager.cityIsSelected = false
                        }
                        .foregroundStyle(.green)

                    }
                }
            }
        }
    }

    #Preview {
        TeleportButton()
    }
#endif
