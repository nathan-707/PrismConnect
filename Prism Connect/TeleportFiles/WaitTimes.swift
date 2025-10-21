//
//  WaitTimes.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 3/4/25.
//
import Foundation

enum ParkCategory {
    case AllDisneyParks
    case AllUniversalParks
    case AllOtherParks
}

struct ThemePark: Hashable, Identifiable {
    var id: Int
    var mainParkName: String
    var subParkName: String
    var city: String
    var state: String
    var country: String
    var parkCategory: ParkCategory
    var funfacts: [String] = []

    func randomFunfact() -> String {
        return funfacts.randomElement()
            ?? "No fun facts available for this theme park."
    }

    func fullLocationName() -> String {
        if state != "" {
            return city + ", " + state + ", " + country
        } else {
            return city + ", " + country
        }
    }

    func fullParkName() -> String {
        if subParkName != "" {
            return mainParkName + " - " + subParkName
        } else {
            return mainParkName
        }
    }

    func pickerName() -> String {
        var pickerName = ""
        if subParkName == "(All Parks)" || subParkName == "" {
            pickerName = mainParkName
        } else {
            pickerName = subParkName + ", " + mainParkName
        }

        if state != "" {
            pickerName =
                pickerName + ", " + city + ", " + state + ", " + country
        } else {
            pickerName = pickerName + ", " + city + ", " + country
        }
        return pickerName
    }
}

enum Park: Int {
    case ALL_DisneyWorld = -100
    case ALL_Disneyland = -200
    case ALL_Universal = -300
    case ALL_Disney_Paris = -400
    case ALL_Disney_Tokyo = -500
    case AnimalKingdom = 8
    case HollywoodStudios = 7
    case MagicKingdom = 6
    case Epcot = 5
    case KingIsland = 60
    case Dollywood = 55
    case Universal_StudiosOrlando = 65
    case Universal_IslandOfAdventureOrlando = 64
    case Universal_VolcanoBay = 67
    case Universal_Beijing = 328
    case Universal_EpicUniverse = 334
    case Universal_Hollywood = 66
    case Universal_Japan = 284
    case FerrariLand = 277
    case Disneyland = 16
    case Disneyland_CaliforniaAdventure = 17
    case Seaworld_Orlando = 21
    case Disney_Shanghai = 30
    case Disney_HongKong = 31
}

let AllDisneyParks: [ThemePark] = [
    ThemePark(
        id: Park.ALL_DisneyWorld.rawValue,
        mainParkName: "Disney World",
        subParkName: "(All Parks)",
        city: "Bay Lake",
        state: "FL",
        country: "U.S.A",
        parkCategory: .AllDisneyParks,
        funfacts: funFactsDisneyWorldAll
    ),
    ThemePark(
        id: Park.MagicKingdom.rawValue,
        mainParkName: "Disney World",
        subParkName: "Magic Kingdom",
        city: "Bay Lake",
        state: "FL",
        country: "U.S.A",
        parkCategory: .AllDisneyParks,
        funfacts: funFactsMagicKingdom
    ),
    ThemePark(
        id: Park.AnimalKingdom.rawValue,
        mainParkName: "Disney World",
        subParkName: "Animal Kingdom",
        city: "Bay Lake",
        state: "FL",
        country: "U.S.A",
        parkCategory: .AllDisneyParks,
        funfacts: funFactsAnimalKingdom
    ),
    ThemePark(
        id: Park.Epcot.rawValue,
        mainParkName: "Disney World",
        subParkName: "Epcot",
        city: "Bay Lake",
        state: "FL",
        country: "U.S.A",
        parkCategory: .AllDisneyParks,
        funfacts: funFactsEpcot
    ),
    ThemePark(
        id: Park.HollywoodStudios.rawValue,
        mainParkName: "Disney World",
        subParkName: "Hollywood Studios",
        city: "Bay Lake",
        state: "FL",
        country: "U.S.A",
        parkCategory: .AllDisneyParks,
        funfacts: funFactsHollywoodStudios
    ),
    ThemePark(
        id: Park.ALL_Disneyland.rawValue,
        mainParkName: "Disneyland",
        subParkName: "(All Parks)",
        city: "Anaheim",
        state: "CA",
        country: "U.S.A",
        parkCategory: .AllDisneyParks,
        funfacts: funFactsDisneylandAllAnaheim
    ),
    ThemePark(
        id: Park.ALL_Disney_Paris.rawValue,
        mainParkName: "Disneyland",
        subParkName: "(All Parks)",
        city: "Paris",
        state: "",
        country: "France",
        parkCategory: .AllDisneyParks,
        funfacts: funFactsDisneylandParis
    ),
    ThemePark(
        id: Park.ALL_Disney_Tokyo.rawValue,
        mainParkName: "Disneyland",
        subParkName: "(All Parks)",
        city: "Tokyo",
        state: "",
        country: "Japan",
        parkCategory: .AllDisneyParks,
        funfacts: funFactsDisneylandTokyo
    ),
    ThemePark(
        id: Park.Disney_Shanghai.rawValue,
        mainParkName: "Disneyland",
        subParkName: "(All Parks)",
        city: "Shanghai",
        state: "",
        country: "China",
        parkCategory: .AllDisneyParks,
        funfacts: funFactsDisneyShanghai
    ),
    ThemePark(
        id: Park.Disney_HongKong.rawValue,
        mainParkName: "Disneyland",
        subParkName: "(All Parks)",
        city: "Hong Kong",
        state: "",
        country: "Hong Kong",
        parkCategory: .AllDisneyParks,
        funfacts: funFactsDisneyHongKong
    ),
]

let AllUniversalParks: [ThemePark] = [
    ThemePark(
        id: Park.ALL_Universal.rawValue,
        mainParkName: "Universal",
        subParkName: "(All Parks)",
        city: "Orlando",
        state: "FL",
        country: "U.S.A",
        parkCategory: .AllUniversalParks,
        funfacts: funFactsUniversalAllOrlando
    ),
    ThemePark(
        id: Park.Universal_EpicUniverse.rawValue,
        mainParkName: "Universal",
        subParkName: "Epic Universe",
        city: "Orlando",
        state: "FL",
        country: "U.S.A",
        parkCategory: .AllUniversalParks,
        funfacts: funFactsEpicUniverse
    ),
    ThemePark(
        id: Park.Universal_StudiosOrlando.rawValue,
        mainParkName: "Universal",
        subParkName: "Universal Studios",
        city: "Orlando",
        state: "FL",
        country: "U.S.A",
        parkCategory: .AllUniversalParks,
        funfacts: funFactsUniversalStudiosFL
    ),
    ThemePark(
        id: Park.Universal_IslandOfAdventureOrlando.rawValue,
        mainParkName: "Universal",
        subParkName: "Island of Adventure",
        city: "Orlando",
        state: "FL",
        country: "U.S.A",
        parkCategory: .AllUniversalParks,
        funfacts: funFactsIslandsOfAdventure
    ),
    ThemePark(
        id: Park.Universal_VolcanoBay.rawValue,
        mainParkName: "Universal",
        subParkName: "Volcano Bay",
        city: "Orlando",
        state: "FL",
        country: "U.S.A",
        parkCategory: .AllUniversalParks,
        funfacts: funFactsVolcanoBay
    ),
    ThemePark(
        id: Park.Universal_Hollywood.rawValue,
        mainParkName: "Universal",
        subParkName: "(All Parks)",
        city: "Hollywood",
        state: "CA",
        country: "U.S.A",
        parkCategory: .AllUniversalParks,
        funfacts: funFactsUniversalHollywood
    ),
    ThemePark(
        id: Park.Universal_Beijing.rawValue,
        mainParkName: "Universal",
        subParkName: "(All Parks)",
        city: "Beijing",
        state: "",
        country: "China",
        parkCategory: .AllUniversalParks,
        funfacts: funFactsUniversalBeijing
    ),
    ThemePark(
        id: Park.Universal_Japan.rawValue,
        mainParkName: "Universal",
        subParkName: "(All Parks)",
        city: "Osaka",
        state: "",
        country: "Japan",
        parkCategory: .AllUniversalParks,
        funfacts: funFactsUniversalJapan
    ),
]

let AllOtherParks: [ThemePark] = [
    ThemePark(
        id: Park.Seaworld_Orlando.rawValue,
        mainParkName: "Seaworld",
        subParkName: "",
        city: "Orlando",
        state: "FL",
        country: "U.S.A",
        parkCategory: .AllOtherParks,
        funfacts: funFactsSeaworldOrlando
    ),
    ThemePark(
        id: Park.Dollywood.rawValue,
        mainParkName: "Dollywood",
        subParkName: "",
        city: "Pigeon Forge",
        state: "TN",
        country: "U.S.A",
        parkCategory: .AllOtherParks,
        funfacts: funFactsDollywood
    ),
    ThemePark(
        id: Park.KingIsland.rawValue,
        mainParkName: "Kings Island",
        subParkName: "",
        city: "Mason",
        state: "OH",
        country: "U.S.A",
        parkCategory: .AllOtherParks,
        funfacts: funFactsKingsIsland
    ),
    ThemePark(
        id: Park.FerrariLand.rawValue,
        mainParkName: "Ferrari Land",
        subParkName: "",
        city: "Tarragona",
        state: "",
        country: "Spain",
        parkCategory: .AllOtherParks,
        funfacts: funFactsFerrariLand
    ),
]

let AllParks: [ThemePark] = AllDisneyParks + AllUniversalParks + AllOtherParks

func matchParkIDtoPark(ID: Int) -> ThemePark {
    for city in AllParks {

        if ID == city.id {
            return city
        }
    }

    return AllParks[0]

}
