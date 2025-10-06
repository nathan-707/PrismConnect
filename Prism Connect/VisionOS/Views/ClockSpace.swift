//
//  ClockSpace.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 4/8/25.
//

#if os(visionOS)
import SwiftUI
import RealityKit
import RealityKitContent
import ARKit
import AVKit

 
struct ClockSpace: View {
    @EnvironmentObject private var prismSessionManager: ClockSessionManager
    @State var weatherManager: WeatherManager!
    
    var body: some View {
        RealityView { content in
            guard let Scene = try? await Entity(named: "ClockScene", in: realityKitContentBundle) else {fatalError()}
            weatherManager = WeatherManager(scene: Scene, weather: prismSessionManager.clock_weather, hour: prismSessionManager.clock_time_hour, min: prismSessionManager.clock_time_min, wholeRoom: prismSessionManager.wholeRoom)
            content.add(weatherManager.clock)
            content.add(weatherManager.anchorRoot)
        }
        
        .onChange(of: prismSessionManager.clock_weather) {
            weatherManager.updateWeather(weatherUpdate: prismSessionManager.clock_weather, wholeRoom: prismSessionManager.wholeRoom)

        }
        .onChange(of: prismSessionManager.clock_time_min) {
            weatherManager.updateTime(hour: String(prismSessionManager.clock_time_hour), min: String(prismSessionManager.clock_time_min))
        }
    }
}

#Preview {
    ClockSpace()
}


#endif











//
//
//
//
//let arSession = ARKitSession()
//
///// The provider instance for scene reconstruction.
//let sceneReconstruction = SceneReconstructionProvider()
//
////            Task {
////                /// The generator to store the root with unlit materials.
////                let generator = MeshAnchorGenerator(root: weatherManager.anchorRoot)
////
////                // Check if the device supports scene reconstruction.
////                guard SceneReconstructionProvider.isSupported else {
////                    print("SceneReconstructionProvider is not supported on this device.")
////                    return
////                }
////
////                do {
////                    // Start the `ARKitSession` and run the `SceneReconstructionProvider`.
////                    try await arSession.run([sceneReconstruction])
////                } catch let error as ARKitSession.Error {
////                    // Handle any `ARKitSession` errors.
////                    print("Encountered an error while running providers: \(error.localizedDescription)")
////                } catch let error {
////                    // Handle other errors.
////                    print("Encountered an unexpected error: \(error.localizedDescription)")
////                }
////
////                // Start the generator if the session runs successfully.
////                await generator.run(sceneReconstruction)
////            }
////
////

//
//@MainActor func videoMaterial() -> VideoMaterial {
//    guard let url = Bundle.main.url(forResource: "sky", withExtension: "mov") else {
//        fatalError("Video file not found.")
//    }
//    
//    let player = AVPlayer(url: url)
//    player.isMuted = true // Mute audio if needed
//    player.play()         // Start playing immediately
//    
//    var material = VideoMaterial(avPlayer: player)
//    
//    
//    // Optional: Improve appearance
//    material.faceCulling = .none // Show both sides if needed
//    material.readsDepth = false  // Don't depth-test if layering over complex geometry
//    material.writesDepth = false // Don’t affect other depth renders
//    
//    return material
//}
