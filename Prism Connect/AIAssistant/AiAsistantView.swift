//
//  AiAsistantView.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 7/10/25.
//

import FoundationModels
import SwiftUI

#if os(iOS)

    @available(iOS 26, *)

    struct AiAsistantView: View {
        @State var requestedAI = false
        @State private var prompt: String = "Surprise me"
        @State private var aiLightControlAssistant: AIAssistant?
        @EnvironmentObject var prismSessionManager: ClockSessionManager
        @State var response: String = ""

        var body: some View {
            VStack {
                if aiLightControlAssistant != nil
                    && aiLightControlAssistant?.session.isResponding == false
                {

                    HStack {
                        TextField("Enter your request...", text: $prompt)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)

                        Button("", systemImage: "arrow.clockwise.circle") {
                            prompt = randomPrompts.randomElement() ?? prompt
                        }
                        .tint(.secondary)
                        .padding(.trailing)
                    }.padding(.vertical, 5)

                    Button("ASK PRISM", systemImage: "sparkles") {
                        aiLightControlAssistant?.clearRational()
                        softImpact.impactOccurred()

                        Task {
                            try await requestAI()
                        }
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .foregroundStyle(.white)

                }

                if let text = aiLightControlAssistant?.assistantResponse?
                    .rationale
                {
                    ScrollView {
                        Text(text).padding(.horizontal)
                    }
                }

                Spacer()

                if aiLightControlAssistant != nil
                    && aiLightControlAssistant?.session.isResponding == false
                {

                    if let masterEffect = aiLightControlAssistant?
                        .assistantResponse?.masterEffect
                    {
                        Divider()
                        Text("- " + masterEffect.title() + " -").bold()
                            .foregroundStyle(.green)
                    }

                    if let topEffect = aiLightControlAssistant?
                        .assistantResponse?.lightEffectOnTop
                    {
                        if aiLightControlAssistant?.assistantResponse?
                            .masterEffect != .onlyShowWeather
                        {
                            Divider()
                            Text(topEffect.title() + " - top").bold()
                        }
                    }

                    if let bottomEffect = aiLightControlAssistant?
                        .assistantResponse?.lightEffectOnBottom
                    {
                        if aiLightControlAssistant?.assistantResponse?
                            .masterEffect != .onlyShowWeather
                        {
                            Divider()
                            Text(bottomEffect.title() + " - bottom").bold()
                        }
                    }
                }

            }

            .task {
                aiLightControlAssistant = AIAssistant(
                    prismSessionManager: prismSessionManager
                )
                aiLightControlAssistant?.prewarm()
                if prompt == "Surprise me" {
                    prompt = randomPrompts.randomElement() ?? prompt
                }
            }

        }

        @MainActor
        func requestAI() async throws {
            requestedAI = true
            do {
                try await aiLightControlAssistant?.suggestLights(prompt: prompt)
                softImpact.impactOccurred()
            } catch {
                aiLightControlAssistant?.error = error
                print(error.localizedDescription)
            }
        }
    }

    let randomPrompts: [String] = [
        "Set the lights to a relaxing scene",
        "Make it a party",
        "Surprise me",
        "Give me focus lighting",
        "Give an action movie scene",
        "Create a reading corner",
        "Give me a gaming mode",
        "Turn on meditation vibes",
        "Set the mood for a stormy night",
        "Make it feel like a nightclub",
        "Give me a workout boost scene",
        "Make it feel like a campfire",
        "Give me a productivity mode",
        "Turn on a dreamy atmosphere",
        "Make it feel like a concert",
        "Set lights for a quiet evening",
        "Set lights for a action movie",
        "Give me a futuristic sci-fi look",
        "Activate battle mode",
        "Make it feel like a car chase",
        "Turn on boss fight lighting",
        "Give me cyberpunk city lights",
        "Set the mood for a stealth mission",
        "Make it feel like an epic finale",
        "Turn on lights for a first-person shooter",
        "Set lights for a sci-fi adventure",
        "Make it feel like a high-tech lab",
        "Turn on a futuristic cityscape",
        "Give me a mystical enchanted forest look",
        "Turn on lights for an apocalyptic world"
    ]

#endif
