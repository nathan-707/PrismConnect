//
//  SleepModeView.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 3/17/25.
//

import SwiftUI

let fiveMin: Int = (60000 * 5)

#if os(iOS)

    struct SleepModeView: View {
        @EnvironmentObject private var prismSessionManager: ClockSessionManager
        @State var sleepTimerSelection: Int = fiveMin
        var body: some View {
            VStack {
                Picker("sleep timer", selection: $sleepTimerSelection) {
                    Text("5 mins").tag(60000 * 5)
                    Text("10 mins").tag(60000 * 10)
                    Text("15 mins").tag(60000 * 15)
                    Text("30 mins").tag(60000 * 30)
                    Text("1 hr").tag(60000 * 60)
                    Text("2 hr").tag(120000 * 60)
                }
                .tint(.green)
                .onSubmit {
                    heavyImpact.impactOccurred()
                    prismSessionManager.sleepTimer = sleepTimerSelection
                    prismSessionManager.updateSettings(
                        nameOfSetting: "sleepTimer",
                        value: sleepTimerSelection
                    )

                }

                if prismSessionManager.pending == false {
                    Button("SET SLEEP TIMER", systemImage: "powersleep") {
                        heavyImpact.impactOccurred()
                        prismSessionManager.sleepTimer = sleepTimerSelection
                        prismSessionManager.updateSettings(
                            nameOfSetting: "sleepTimer",
                            value: sleepTimerSelection
                        )
                        prismSessionManager.ping()
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .foregroundStyle(.white)
                } else {
                    ProgressView()
                }

            }
        }
    }

    #Preview {
        SleepModeView()
    }
#endif
