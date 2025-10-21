import Foundation
import FoundationModels

@available(iOS 26, *)

@Generable
struct PrismAssistant {

    @Generable
    enum LightEffects: Int, Codable {
        case Spectrum,
            Headless,
            ShortCircuit,
            ColorClock,
            TempClock,
            CustomColor,
            FireMode

        func index() -> Int {
            return self.rawValue + 1
        }

        func title() -> String {
            switch self {
            case .Spectrum: return "Spectrum Mode"
            case .Headless: return "Headless Mode"
            case .ShortCircuit: return "Short Circuit Mode"
            case .ColorClock: return "Color Clock"
            case .TempClock: return "Temp Clock"
            case .CustomColor: return "Custom Color"
            case .FireMode: return "Fire Mode"
            }
        }
    }

    @Generable
    enum MasterEffect {
        case onlyShowEffect
        case showBoth
        case onlyShowWeather

        func title() -> String {
            switch self {
            case .onlyShowEffect: return "Light Effect Only"
            case .showBoth: return "Weather & Effect"
            case .onlyShowWeather: return "Only Weather"
            }
        }
    }

    @Guide(
        description: """
            This field controls how the PrismBox divides its LEDs between aesthetic light effects and weather visualization. Choose:

            • `onlyShowEffect`: All LEDs display the selected light effects. Weather visuals are disabled.
            • `showBoth`: LEDs are split — half for light effects, half for live weather visuals.
            • `onlyShowWeather`: All LEDs show weather visualization only. *If this is selected, `lightEffectOnTop` and `lightEffectOnBottom` are completely ignored, so do not explain your choices for them.*
            """
    )
    var masterEffect: MasterEffect

    @Guide(
        description: """
            This controls the light effect for the top half of the PrismBox. It only applies if `masterEffect` is not set to `onlyShowWeather`. Choose based on the user's emotional tone, environment, or preference:

            • `Spectrum`: smooth color fades through the spectrum (calm, ambient)
            • `Headless`: fast, chaotic independent fades per LED (energetic, glitchy)
            • `ShortCircuit`: exciting with intense purple flashes
            • `ColorClock`: reflects time of day with slow color changes
            • `TempClock`: reflects temperature using color mapping (blue/green/red)
            • `CustomColor`: user's favorite static color
            • `FireMode`: flickering warm tones (cozy or intense vibe)

            If `masterEffect` is set to `onlyShowWeather`, this setting has no visual effect and should not be discussed in the rationale.
            """
    )
    var lightEffectOnTop: LightEffects

    @Guide(
        description: """
            This controls the light effect for the bottom half of the PrismBox. It only applies if `masterEffect` is not set to `onlyShowWeather`. Choose from:

            • `Spectrum`: smooth spectrum transitions
            • `Headless`: independent fast fades per LED
            • `ShortCircuit`: exciting with intense purple flashes
            • `ColorClock`: light pattern tied to time of day
            • `TempClock`: temp-based coloring
            • `CustomColor`: personal static color
            • `FireMode`: warm flickering light

            If `masterEffect` is set to `onlyShowWeather`, this setting is ignored and does not affect the visual output.
            """
    )
    var lightEffectOnBottom: LightEffects

    @Guide(
        description: """
            Explain clearly *why* you selected the `masterEffect`, and how it satisfies the user's request. If `onlyShowWeather` is chosen, do **not** explain or justify `lightEffectOnTop` and `lightEffectOnBottom` — they will not appear. If any other mode is used, explain your reasoning behind the top and bottom effects separately, and how they complement the user's emotional tone, use case, or preferences.
            """
    )
    let rationale: String
}

let aiColorModePickerAssistantInstructions = """
    You are the AI assistant for the PrismBox app. Your job is to control the lighting system on the PrismBox device. You may also have to get creative if the user ask for a vibe. You have access to multiple light effects that can be activated on command. These include custom color mode which simply shows the users favorite color they set; Spectrum mode, where the entire clock fades through all colors together; Headless mode, where each individual LED fades quickly through the spectrum of colors independently through its own time; Short Circuit mode, which gives the lights electric vibes with random flashes of purple that surges across the LEDs; Fire mode, which mimics a flickering flame with a warm gradient from yellow to orange to red; Color Clock mode, where the lights are mapped to the time of day and gradually cycle through the color spectrum every 12 hours; and insightful Temp Clock mode which maps the lighting to the outdoor temperature—blue for cool, green for mild, and red for hot. dont be scared to pick short circuit mode, temp clock mode, or the onlyshowweather master effect. 

    you also control the master effect setting, which determines how the lighting is split between aesthetic effects and weather visualization. The master effect has three modes: Effect Only, which uses all LEDs to display the selected light effect; Both, which splits the LEDs so half display the chosen light effect while the other half shows current weather conditions; and Weather Only, where all LEDs are dedicated solely to displaying the weather and no visual effects are shown. You are expected to follow user commands to change both the light effects and the master effect setting as needed.
    """

@available(iOS 26, *)
@Generable
struct AIFunfact {
    @Guide(description: "Interesting fact about the given location.")
    var funfact: String
}
