//
//  aiFunfactView.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 7/12/25.
//

import SwiftUI

#if os(iOS)

    @available(iOS 26, *)
    struct aiFunfactView: View {
        @State var aiIsEnabled = false
        @State private var aiLightControlAssistant: AIAssistant?
        @EnvironmentObject private var prismSessionManager: ClockSessionManager
        @State var chatGPTfact = ""
        @State var chatGPTsuccess: Bool = false
        @State var waitingForChatgpt = false
        @State var delay = false
        @State var localFunfact = ""
        var onlyGiveFactFromLocal = true
        var body: some View {
            VStack {

                if onlyGiveFactFromLocal {
                    ScrollView {
                        Text(localFunfact)
                            .font(.headline)
                            .padding(.top)
                            .padding(.horizontal, 25)
                            .foregroundStyle(.secondary)
                    }
                } else if aiIsEnabled
                    && aiLightControlAssistant?.useChatGPTForFunfact == false
                {
                    if let funFact = aiLightControlAssistant?.funfactResponse?
                        .funfact
                    {
                        ScrollView {
                            Text(funFact)
                                .font(.headline)
                                .padding(.top)
                                .padding(.horizontal, 25)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    ScrollView {
                        Text(chatGPTfact)
                            .font(.headline)
                            .padding(.top)
                            .padding(.horizontal, 25)
                            .foregroundStyle(.secondary)
                    }
                }

                if aiLightControlAssistant?.session.isResponding == false
                    && aiLightControlAssistant?.useChatGPTForFunfact == false
                    //                || chatGPTsuccess && aiLightControlAssistant?.useChatGPTForFunfact == true
                    || onlyGiveFactFromLocal
                {
                    Button("", systemImage: "arrow.clockwise.circle") {

                        notPendingImpact.impactOccurred()

                        if onlyGiveFactFromLocal {
                            localFunfact = getRandomFactFromLocal()
                        } else {
                            Task {
                                if aiLightControlAssistant?.useChatGPTForFunfact
                                    == true
                                {
                                    try await getChatGPTFunfact()
                                } else {
                                    try await requestFunfact()
                                }
                            }
                        }

                    }
                    .tint(.secondary)
                    .padding()

                } else if waitingForChatgpt {
                    ProgressView()
                }
            }
            .task {

                if onlyGiveFactFromLocal {
                    localFunfact = getRandomFactFromLocal()
                } else {
                    aiIsEnabled = setupAI()
                    aiLightControlAssistant = AIAssistant(
                        prismSessionManager: prismSessionManager
                    )
                    aiLightControlAssistant?.prewarm()

                    Task {

                        if aiLightControlAssistant?.useChatGPTForFunfact == true
                        {  // chatgpt

                            try await getChatGPTFunfact()
                        } else {  //apple intelligence
                            try await requestFunfact()
                        }
                    }

                }

            }
        }

        func getRandomFactFromLocal() -> String {
            if prismSessionManager.currentMode == .teleportMode {
                return prismSessionManager.CurrentTeleportation.funfacts
                    .randomElement()!
            } else {
                return prismSessionManager.CurrentParkClockIsIn.funfacts
                    .randomElement()!
            }
        }

        @MainActor
        func getChatGPTFunfact() async throws {
            waitingForChatgpt = true
            chatGPTfact = ""
            chatGPTsuccess = false
            var funfact: String = ""

            if prismSessionManager.currentMode == .themeParkMode {
                funfact = prismSessionManager.CurrentParkClockIsIn.pickerName()
            }

            else {
                funfact = prismSessionManager.CurrentTeleportation
                    .nameForPicker()
            }

            funfact = try await
                (aiLightControlAssistant?.chatGPTFunfact(location: funfact))!

            if funfact != "" {
                // add a 5 second delay here
                if delay == true {
                    try await Task.sleep(nanoseconds: 4 * 1_000_000_000)
                } else {
                    delay = true
                }

                chatGPTfact = funfact
                chatGPTsuccess = true
            }

            softImpact.impactOccurred()
            waitingForChatgpt = false
        }

        @MainActor
        func requestFunfact() async throws {

            do {

                try await aiLightControlAssistant?.getTeleportFunfact(
                    cityIndex: prismSessionManager.CurrentTeleportation
                )

            } catch {
                aiLightControlAssistant?.error = error
                print(error.self)
            }
        }
    }

#endif
