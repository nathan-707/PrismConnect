//
//  AIResponse.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 7/11/25.
//

/*
 See the LICENSE.txt file for this sample’s licensing information.
 
 Abstract:
 A class that generates an itinerary by streaming the response output in its partially generated form.
 */

import FoundationModels
import Observation

@available(iOS 26, *)

@Observable
@MainActor
final class AIAssistant {
    
    let useChatGPTForFunfact: Bool = false
    
    func prewarm() {
        session.prewarm()
    }
    
    func clearRational(){
        assistantResponse?.rationale = ""
    }
    
    private(set) var assistantResponse: PrismAssistant.PartiallyGenerated?
    private(set) var funfactResponse: AIFunfact.PartiallyGenerated?
    var session: LanguageModelSession
    var error: Error?
    var prismSessionManager: ClockSessionManager
    
    let funfactInstructions = "You are a tour guide that gives 100 percent true facts about the given locations. Use the database with the getfunfact tool to create a funfact based on the database."
    
    let lightAIoptions = GenerationOptions(temperature: 0.8)
    let funfactOptions = GenerationOptions()


    init(prismSessionManager: ClockSessionManager) {
        self.session = LanguageModelSession(
            instructions: aiColorModePickerAssistantInstructions
        )
        
        self.prismSessionManager = prismSessionManager
    }
    
    func suggestLights(prompt: String) async throws {
        
        let myModel = SystemLanguageModel( guardrails: .permissiveContentTransformations)

        self.session = LanguageModelSession(model: myModel, instructions: aiColorModePickerAssistantInstructions)
    
//        let genOptions = GenerationOptions( temperature: 1.25)

        
        let stream = session.streamResponse(
            generating: PrismAssistant.self,
            includeSchemaInPrompt: true, options: lightAIoptions,

            prompt: { Prompt(prompt) }
        )
        
        for try await partialResponse in stream {
            assistantResponse = partialResponse.content
        }
        
        // async response done here.
        switch assistantResponse?.masterEffect {
        case .onlyShowWeather:
            prismSessionManager.masterEffect = .onlyShowW
            prismSessionManager.updateMasterEffect(update: .onlyShowW)
        case .showBoth:
            prismSessionManager.masterEffect = .showW
            prismSessionManager.updateMasterEffect(update: .showW)
        case .onlyShowEffect:
            prismSessionManager.masterEffect = .fullEff
            prismSessionManager.updateMasterEffect(update: .fullEff)
        case .none:
            break
        }
        
        let topMode = assistantResponse?.lightEffectOnBottom?.index() ?? 0
        let bottomMode = assistantResponse?.lightEffectOnTop?.index() ?? 0
        
        print(topMode, bottomMode)
        prismSessionManager.smallMode = topMode
        prismSessionManager.updateSettings(nameOfSetting: "smallMode", value: topMode)
        prismSessionManager.largeMode = bottomMode
        prismSessionManager.updateSettings(nameOfSetting: "largeMode", value: bottomMode)
        prismSessionManager.currentLightEffect = .dualmode_m
        prismSessionManager.sendCommand(command: .dualmode_m)
    }
    
    
    func chatGPTFunfact(location: String) async throws -> String {
        let response = try await ChatGPTClient.shared.sendMessage("Give me a truely random funfact for the given location. this may be called a lot and i want a different fact everytime.  \(location)")
        return response
    }
    
    
    func getTeleportFunfact(cityIndex: City) async throws {
        
        
        let myModel = SystemLanguageModel( guardrails: .permissiveContentTransformations)

        self.session = LanguageModelSession(model: myModel, tools: [GetFunfactBasedOffInformationTool()], instructions: funfactInstructions)

    
        let stream = session.streamResponse(
            generating: AIFunfact.self,
            includeSchemaInPrompt: true, options: funfactOptions,
            prompt: { "Use the given tool to learn about \(Prompt(cityIndex.city)) then give a funfact based on what you learn from the on board database through the tool." }
        )
    
        for try await partialResponse in stream {
            funfactResponse = partialResponse.content
        }
//        print("DONE FUN")
    }
}

