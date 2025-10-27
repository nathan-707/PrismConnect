//
//  ParkPicker.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 3/4/25.
//

import SwiftUI

#if os(iOS)

    let editSymbol = "slider.horizontal.2.square"

    struct ThemeParkButton: View {
        @EnvironmentObject private var prismSessionManager: ClockSessionManager
        @State var themeParkPicker = false
        var body: some View {

            HStack {
                Button("THEME PARK", systemImage: "wand.and.sparkles") {
                    heavyImpact.impactOccurred()
                    prismSessionManager.pending = true
                    prismSessionManager.pendingMode = .themeParkMode
                    prismSessionManager.sendCommand(command: .themeParkMode)
                }
                .controlSize(.large)
                .buttonStyle(.glassProminent)
                .tint(
                    prismSessionManager.prismboxVersion?.color ?? .accentColor
                )
                .foregroundStyle(.white)

                Button {
                    mediumImpact.impactOccurred()
                    themeParkPicker = true
                } label: {
                    Image(systemName: "slider.horizontal.2.square")
                        .foregroundStyle(.selection)
                        .scaleEffect(1.5)

                }
                .padding(.horizontal, 5)
            }

            .sheet(isPresented: $themeParkPicker) {
                Text("Change Theme Park").font(.title).bold().padding()

                Text(prismSessionManager.selectedPark.pickerName()).bold()

                List {
                    ForEach(AllParks) { park in
                        Button(
                            park.fullParkName() + ", " + park.fullLocationName()
                        ) {
                            prismSessionManager.selectedPark = park
                            themeParkPicker = false
                        }
                    }
                }
            }
        }
    }

    // Ensure preview works
    #Preview {
        ThemeParkButton()
            .environmentObject(ClockSessionManager())  // Provide a mock environment object
    }

#endif
