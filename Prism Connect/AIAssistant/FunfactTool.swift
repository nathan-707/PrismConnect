//
//  FunfactTool.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 9/2/25.
//

import Foundation
import FoundationModels


@available(iOS 26, *)
struct GetFunfactBasedOffInformationTool: Tool {
    let name = "GetFunfactTool"
    let description = "Generate a funfact based off the database of funfacts for the given location"

    @Generable
    enum WhichArray {
        case city, park
    }
    
    
    @Generable
    struct Arguments {
        @Guide(description: "The index of the city to generate a funfact for")
        let locationName: String
        
        
        @Guide(description: "Funfact for a city or theme park")
        let cityOrPark: WhichArray
    }


    func call(arguments: Arguments) async throws -> [String] {
        
        print(arguments.cityOrPark)
        print(arguments.locationName)
        
        if arguments.cityOrPark == .city {
            for city in ALL_CITIES {
                if city.city == arguments.locationName {
                    print("city found.")
                    return [city.funfacts.randomElement()!]
                }
            }
        }
        
        return []
    }
}
