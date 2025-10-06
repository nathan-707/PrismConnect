//
//  TeleportCities.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 3/5/25.
//

import Foundation
import CoreLocation
import WeatherKit
import MapKit




func returnCityFromID(ID: Int) -> City {
    for city in ALL_CITIES {
        if city.id == ID {
            return city
        }
    }
    
    return ALL_CITIES[0]
    
}



struct City: Identifiable, Hashable {
    var id: Int
    var city: String
    var territory: String
    var coreLocation: CLLocation
    var funfacts: [String] = []
    var lastWeatherFetch: Date? = nil
    var weatherCache: Weather = Weather()
    
    func randomFunfact()-> String {
        return funfacts.randomElement() ?? "No fun facts available for this city."
    }
    
    func nameForPicker() -> String {
        if self == worldTourCity  {
            return "World Tour - Cycle Through All"
        } else if self == randomLocationCity {
            return "Random Location"
        }
        
        return self.city + ", " + self.territory
    }
    
    static func == (lhs: City, rhs: City) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

let worldTour = 149
let randomLocation = 148

let randomLocationCity = City(id: randomLocation, city: "Random Location", territory: "", coreLocation: CLLocation(latitude: 0, longitude: 00))
let worldTourCity = City(id: worldTour, city: "World Tour", territory: "(Cycle Through All)", coreLocation: CLLocation(latitude: 0, longitude: 00))

let emptyCity = City(id: 100, city: "--", territory: "--", coreLocation: CLLocation())

let CityModes: [City] = [
    worldTourCity, randomLocationCity
]

// US cities (IDs 0–60) – now with funfacts:
let US_CITIES: [City] = [
    City(id: 0,  city: "Birmingham",      territory: "Alabama",         coreLocation: CLLocation(latitude: 33.5207, longitude: -86.8025), funfacts: funFactsBirmingham),
    City(id: 1,  city: "Anchorage",       territory: "Alaska",          coreLocation: CLLocation(latitude: 61.2181, longitude: -149.9003), funfacts: funFactsAnchorage),
    City(id: 2,  city: "Utqiaġvik",       territory: "Alaska",          coreLocation: CLLocation(latitude: 71.2905, longitude: -156.7886), funfacts: funFactsUtqiagvik),
    City(id: 3,  city: "Phoenix",         territory: "Arizona",         coreLocation: CLLocation(latitude: 33.4484, longitude: -112.0740), funfacts: funFactsPhoenix),
    City(id: 4,  city: "Little Rock",     territory: "Arkansas",        coreLocation: CLLocation(latitude: 34.7465, longitude: -92.2896), funfacts: funFactsLittleRock),
    City(id: 5,  city: "Anaheim",         territory: "California",      coreLocation: CLLocation(latitude: 33.8352, longitude: -117.9145), funfacts: funFactsAnaheim),
    City(id: 6,  city: "Death Valley",    territory: "California",      coreLocation: CLLocation(latitude: 36.5626, longitude: -116.9672), funfacts: funFactsDeathValley),
    City(id: 7,  city: "Hollywood",       territory: "California",      coreLocation: CLLocation(latitude: 34.0522, longitude: -118.2437), funfacts: funFactsHollywood),
    City(id: 8,  city: "San Diego",       territory: "California",      coreLocation: CLLocation(latitude: 32.7157, longitude: -117.1611), funfacts: funFactsSanDiego),
    City(id: 9,  city: "Denver",          territory: "Colorado",        coreLocation: CLLocation(latitude: 39.7392, longitude: -104.9903), funfacts: funFactsDenver),
    City(id: 10, city: "Bridgeport",      territory: "Connecticut",     coreLocation: CLLocation(latitude: 41.1865, longitude: -73.1952), funfacts: funFactsBridgeport),
    City(id: 11, city: "Wilmington",      territory: "Delaware",        coreLocation: CLLocation(latitude: 39.7391, longitude: -75.5398), funfacts: funFactsWilmington),
    City(id: 12, city: "Bay Lake",        territory: "Florida",         coreLocation: CLLocation(latitude: 28.3874, longitude: -81.5658), funfacts: funFactsBayLake),
    City(id: 13, city: "Key West",        territory: "Florida",         coreLocation: CLLocation(latitude: 24.5551, longitude: -81.7799), funfacts: funFactsKeyWest),
    City(id: 14, city: "Orlando",         territory: "Florida",         coreLocation: CLLocation(latitude: 28.5383, longitude: -81.3792), funfacts: funFactsOrlando),
    City(id: 15, city: "Miami",           territory: "Florida",         coreLocation: CLLocation(latitude: 25.7617, longitude: -80.1918), funfacts: funFactsMiami),
    City(id: 16, city: "Atlanta",         territory: "Georgia",         coreLocation: CLLocation(latitude: 33.7490, longitude: -84.3880), funfacts: funFactsAtlanta),
    City(id: 17, city: "Honolulu",        territory: "Hawaii",          coreLocation: CLLocation(latitude: 21.3069, longitude: -157.8583), funfacts: funFactsHonolulu),
    City(id: 18, city: "Boise",           territory: "Idaho",           coreLocation: CLLocation(latitude: 43.6150, longitude: -116.2023), funfacts: funFactsBoise),
    City(id: 19, city: "Chicago",         territory: "Illinois",        coreLocation: CLLocation(latitude: 41.8781, longitude: -87.6298), funfacts: funFactsChicago),
    City(id: 20, city: "Indianapolis",    territory: "Indiana",         coreLocation: CLLocation(latitude: 39.7684, longitude: -86.1581), funfacts: funFactsIndianapolis),
    City(id: 21, city: "Des Moines",      territory: "Iowa",            coreLocation: CLLocation(latitude: 41.5868, longitude: -93.6250), funfacts: funFactsDesMoines),
    City(id: 22, city: "Wichita",         territory: "Kansas",          coreLocation: CLLocation(latitude: 37.6872, longitude: -97.3301), funfacts: funFactsWichita),
    City(id: 23, city: "Louisville",      territory: "Kentucky",        coreLocation: CLLocation(latitude: 38.2527, longitude: -85.7585), funfacts: funFactsLouisville),
    City(id: 24, city: "Elizabethtown",   territory: "Kentucky",        coreLocation: CLLocation(latitude: 37.7032, longitude: -85.8591), funfacts: funFactsElizabethtown),
    City(id: 25, city: "New Orleans",     territory: "Louisiana",       coreLocation: CLLocation(latitude: 29.9511, longitude: -90.0715), funfacts: funFactsNewOrleans),
    City(id: 26, city: "Portland",        territory: "Maine",           coreLocation: CLLocation(latitude: 43.6591, longitude: -70.2568), funfacts: funFactsPortlandME),
    City(id: 27, city: "Baltimore",       territory: "Maryland",        coreLocation: CLLocation(latitude: 39.2904, longitude: -76.6122), funfacts: funFactsBaltimore),
    City(id: 28, city: "Boston",          territory: "Massachusetts",   coreLocation: CLLocation(latitude: 42.3601, longitude: -71.0589), funfacts: funFactsBoston),
    City(id: 29, city: "Detroit",         territory: "Michigan",        coreLocation: CLLocation(latitude: 42.3314, longitude: -83.0458), funfacts: funFactsDetroit),
    City(id: 30, city: "Minneapolis",     territory: "Minnesota",       coreLocation: CLLocation(latitude: 44.9778, longitude: -93.2650), funfacts: funFactsMinneapolis),
    City(id: 31, city: "Jackson",         territory: "Mississippi",     coreLocation: CLLocation(latitude: 32.2988, longitude: -90.1848), funfacts: funFactsJacksonMS),
    City(id: 32, city: "Kansas City",     territory: "Missouri",        coreLocation: CLLocation(latitude: 39.0997, longitude: -94.5786), funfacts: funFactsKansasCity),
    City(id: 33, city: "Saint Louis",     territory: "Missouri",        coreLocation: CLLocation(latitude: 38.6270, longitude: -90.1994), funfacts: funFactsStLouis),
    City(id: 34, city: "Billings",        territory: "Montana",         coreLocation: CLLocation(latitude: 45.7833, longitude: -108.5007), funfacts: funFactsBillings),
    City(id: 35, city: "Omaha",           territory: "Nebraska",        coreLocation: CLLocation(latitude: 41.2565, longitude: -95.9345), funfacts: funFactsOmaha),
    City(id: 36, city: "Las Vegas",       territory: "Nevada",          coreLocation: CLLocation(latitude: 36.1699, longitude: -115.1398), funfacts: funFactsLasVegas),
    City(id: 37, city: "Dover",           territory: "New Hampshire",   coreLocation: CLLocation(latitude: 43.1975, longitude: -70.8806), funfacts: funFactsDover),
    City(id: 38, city: "Newark",          territory: "New Jersey",      coreLocation: CLLocation(latitude: 40.7357, longitude: -74.1724), funfacts: funFactsNewark),
    City(id: 39, city: "Albuquerque",     territory: "New Mexico",      coreLocation: CLLocation(latitude: 35.0844, longitude: -106.6504), funfacts: funFactsAlbuquerque),
    City(id: 40, city: "New York",        territory: "New York",        coreLocation: CLLocation(latitude: 40.7128, longitude: -74.0060), funfacts: funFactsNewYork),
    City(id: 41, city: "Charlotte",       territory: "North Carolina",  coreLocation: CLLocation(latitude: 35.2271, longitude: -80.8431), funfacts: funFactsCharlotte),
    City(id: 42, city: "Morehead City",   territory: "North Carolina",  coreLocation: CLLocation(latitude: 34.7193, longitude: -76.6413), funfacts: funFactsMoreheadCity),
    City(id: 43, city: "Fargo",           territory: "North Dakota",    coreLocation: CLLocation(latitude: 46.8772, longitude: -96.7898), funfacts: funFactsFargo),
    City(id: 44, city: "Mason",           territory: "Ohio",            coreLocation: CLLocation(latitude: 39.3600, longitude: -84.3099), funfacts: funFactsMason),
    City(id: 45, city: "Oklahoma City",   territory: "Oklahoma",        coreLocation: CLLocation(latitude: 35.4676, longitude: -97.5164), funfacts: funFactsOklahomaCity),
    City(id: 46, city: "Portland",        territory: "Oregon",          coreLocation: CLLocation(latitude: 45.5051, longitude: -122.6750), funfacts: funFactsPortlandOR),
    City(id: 47, city: "Philadelphia",    territory: "Pennsylvania",    coreLocation: CLLocation(latitude: 39.9526, longitude: -75.1652), funfacts: funFactsPhiladelphia),
    City(id: 48, city: "Providence",      territory: "Rhode Island",    coreLocation: CLLocation(latitude: 41.8240, longitude: -71.4128), funfacts: funFactsProvidence),
    City(id: 49, city: "Charleston",      territory: "South Carolina",  coreLocation: CLLocation(latitude: 32.7765, longitude: -79.9311), funfacts: funFactsCharlestonSC),
    City(id: 50, city: "Sioux Falls",     territory: "South Dakota",    coreLocation: CLLocation(latitude: 43.5446, longitude: -96.7311), funfacts: funFactsSiouxFalls),
    City(id: 51, city: "Pigeon Forge",    territory: "Tennessee",       coreLocation: CLLocation(latitude: 35.7884, longitude: -83.5543), funfacts: funFactsPigeonForge),
    City(id: 52, city: "Nashville",       territory: "Tennessee",       coreLocation: CLLocation(latitude: 36.1627, longitude: -86.7816), funfacts: funFactsNashville),
    City(id: 53, city: "Houston",         territory: "Texas",           coreLocation: CLLocation(latitude: 29.7604, longitude: -95.3698), funfacts: funFactsHouston),
    City(id: 54, city: "Salt Lake City",  territory: "Utah",            coreLocation: CLLocation(latitude: 40.7608, longitude: -111.8910), funfacts: funFactsSaltLakeCity),
    City(id: 55, city: "Burlington",      territory: "Vermont",         coreLocation: CLLocation(latitude: 44.4759, longitude: -73.2121), funfacts: funFactsBurlington),
    City(id: 56, city: "Virginia Beach",  territory: "Virginia",        coreLocation: CLLocation(latitude: 36.8529, longitude: -75.9780), funfacts: funFactsVirginiaBeach),
    City(id: 57, city: "Seattle",         territory: "Washington",      coreLocation: CLLocation(latitude: 47.6062, longitude: -122.3321), funfacts: funFactsSeattle),
    City(id: 58, city: "Charleston",      territory: "West Virginia",   coreLocation: CLLocation(latitude: 38.3498, longitude: -81.6326), funfacts: funFactsCharlestonWV),
    City(id: 59, city: "Milwaukee",       territory: "Wisconsin",       coreLocation: CLLocation(latitude: 43.0389, longitude: -87.9065), funfacts: funFactsMilwaukee),
    City(id: 60, city: "Cheyenne",        territory: "Wyoming",         coreLocation: CLLocation(latitude: 41.1400, longitude: -104.8202), funfacts: funFactsCheyenne)
]

// WORLD cities (IDs 61–146) – now with funfacts:
let WORLD_CITIES: [City] = [
    City(id: 61,  city: "Kabul",            territory: "Afghanistan",           coreLocation: CLLocation(latitude: 34.5553, longitude: 69.2075),  funfacts: funFactsKabul),
    City(id: 62,  city: "McMurdo",          territory: "Antarctica",            coreLocation: CLLocation(latitude: -77.8419, longitude: 166.6863), funfacts: funFactsMcMurdo),
    City(id: 63,  city: "Buenos Aires",     territory: "Argentina",             coreLocation: CLLocation(latitude: -34.6037, longitude: -58.3816), funfacts: funFactsBuenosAires),
    City(id: 64,  city: "Queensland",       territory: "Australia",             coreLocation: CLLocation(latitude: -27.4698, longitude: 153.0251), funfacts: funFactsQueensland),
    City(id: 65,  city: "Vienna",           territory: "Austria",               coreLocation: CLLocation(latitude: 48.2082, longitude: 16.3738),   funfacts: funFactsVienna),
    City(id: 66,  city: "Brussels",         territory: "Belgium",               coreLocation: CLLocation(latitude: 50.8503, longitude: 4.3517),    funfacts: funFactsBrussels),
    City(id: 67,  city: "Sao Paulo",        territory: "Brazil",                coreLocation: CLLocation(latitude: -23.5505, longitude: -46.6333), funfacts: funFactsSaoPaulo),
    City(id: 68,  city: "Rio de Janeiro",   territory: "Brazil",                coreLocation: CLLocation(latitude: -22.9068, longitude: -43.1729), funfacts: funFactsRioDeJaneiro),
    City(id: 69,  city: "Siem Reap",        territory: "Cambodia",              coreLocation: CLLocation(latitude: 13.3670, longitude: 103.8448),  funfacts: funFactsSiemReap),
    City(id: 70,  city: "Alert",            territory: "Canada",                coreLocation: CLLocation(latitude: 82.5084, longitude: -62.4105),  funfacts: funFactsAlert),
    City(id: 71,  city: "Toronto",          territory: "Canada",                coreLocation: CLLocation(latitude: 43.6532, longitude: -79.3832),  funfacts: funFactsToronto),
    City(id: 72,  city: "Cartagena",        territory: "Colombia",              coreLocation: CLLocation(latitude: 10.3910, longitude: -75.4794),  funfacts: funFactsCartagena),
    City(id: 73,  city: "West Bay",         territory: "Cayman Islands",        coreLocation: CLLocation(latitude: 19.2850, longitude: -81.3840),  funfacts: funFactsWestBay),
    City(id: 74,  city: "Santiago",         territory: "Chile",                 coreLocation: CLLocation(latitude: -33.4489, longitude: -70.6693), funfacts: funFactsSantiago),
    City(id: 75,  city: "Beijing",          territory: "China",                 coreLocation: CLLocation(latitude: 40.1906, longitude: 116.4121),  funfacts: funFactsBeijing),
    City(id: 76,  city: "Shanghai",         territory: "China",                 coreLocation: CLLocation(latitude: 31.2304, longitude: 121.4737),  funfacts: funFactsShanghai),
    City(id: 77,  city: "Brazzaville",      territory: "Congo",                 coreLocation: CLLocation(latitude: -4.2634, longitude: 15.2429),   funfacts: funFactsBrazzaville),
    City(id: 78,  city: "San Jose",         territory: "Costa Rica",            coreLocation: CLLocation(latitude: 9.9281, longitude: -84.0907),   funfacts: funFactsSanJose),
    City(id: 79,  city: "Havana",           territory: "Cuba",                  coreLocation: CLLocation(latitude: 23.1136, longitude: -82.3666),  funfacts: funFactsHavana),
    City(id: 80,  city: "Copenhagen",       territory: "Denmark",               coreLocation: CLLocation(latitude: 55.6761, longitude: 12.5683),   funfacts: funFactsCopenhagen),
    City(id: 81,  city: "Quito",            territory: "Ecuador",               coreLocation: CLLocation(latitude: -0.1807, longitude: -78.4678),  funfacts: funFactsQuito),
    City(id: 82,  city: "Cairo",            territory: "Egypt",                 coreLocation: CLLocation(latitude: 30.0444, longitude: 31.2357),   funfacts: funFactsCairo),
    City(id: 83,  city: "Helsinki",         territory: "Finland",               coreLocation: CLLocation(latitude: 60.1699, longitude: 24.9384),   funfacts: funFactsHelsinki),
    City(id: 84,  city: "Bora Bora",        territory: "French Polynesia",      coreLocation: CLLocation(latitude: -16.4997, longitude: -151.7705),funfacts: funFactsBoraBora),
    City(id: 85,  city: "Paris",            territory: "France",                coreLocation: CLLocation(latitude: 48.8566, longitude: 2.3522),    funfacts: funFactsParis),
    City(id: 86,  city: "Berlin",           territory: "Germany",               coreLocation: CLLocation(latitude: 52.5200, longitude: 13.4050),   funfacts: funFactsBerlin),
    City(id: 87,  city: "Athens",           territory: "Greece",                coreLocation: CLLocation(latitude: 37.9838, longitude: 23.7275),   funfacts: funFactsAthens),
    City(id: 88,  city: "Nuuk",             territory: "Greenland",             coreLocation: CLLocation(latitude: 64.1830, longitude: -51.7216),  funfacts: funFactsNuuk),
    City(id: 89,  city: "Hong Kong",        territory: "Hong Kong",             coreLocation: CLLocation(latitude: 22.3193, longitude: 114.1694),  funfacts: funFactsHongKong),
    City(id: 90,  city: "Budapest",         territory: "Hungary",               coreLocation: CLLocation(latitude: 47.4979, longitude: 19.0402),   funfacts: funFactsBudapest),
    City(id: 91,  city: "Reykjavik",        territory: "Iceland",               coreLocation: CLLocation(latitude: 64.1265, longitude: -21.8174),  funfacts: funFactsReykjavik),
    City(id: 92,  city: "Mawsynram",        territory: "India",                 coreLocation: CLLocation(latitude: 25.2990, longitude: 91.5833),   funfacts: funFactsMawsynram),
    City(id: 93,  city: "Mumbai",           territory: "India",                 coreLocation: CLLocation(latitude: 19.0760, longitude: 72.8777),   funfacts: funFactsMumbai),
    City(id: 94,  city: "Sanandaj",         territory: "Iran",                  coreLocation: CLLocation(latitude: 35.3149, longitude: 46.9986),   funfacts: funFactsSanandaj),
    City(id: 95,  city: "Baghdad",          territory: "Iraq",                  coreLocation: CLLocation(latitude: 33.3128, longitude: 44.3615),   funfacts: funFactsBaghdad),
    City(id: 96,  city: "Dublin",           territory: "Ireland",               coreLocation: CLLocation(latitude: 53.3498, longitude: -6.2603),   funfacts: funFactsDublin),
    City(id: 97,  city: "Milan",            territory: "Italy",                 coreLocation: CLLocation(latitude: 45.4642, longitude: 9.1900),    funfacts: funFactsMilan),
    City(id: 98,  city: "Kingston",         territory: "Jamaica",               coreLocation: CLLocation(latitude: 17.9714, longitude: -76.7936),  funfacts: funFactsKingston),
    City(id: 99,  city: "Aomori",           territory: "Japan",                 coreLocation: CLLocation(latitude: 40.8222, longitude: 140.7474),  funfacts: funFactsAomori),
    City(id: 100, city: "Hiroshima",        territory: "Japan",                 coreLocation: CLLocation(latitude: 34.3853, longitude: 132.4553),  funfacts: funFactsHiroshima),
    City(id: 101, city: "Nagasaki",         territory: "Japan",                 coreLocation: CLLocation(latitude: 32.7503, longitude: 129.8777),  funfacts: funFactsNagasaki),
    City(id: 102, city: "Osaka",            territory: "Japan",                 coreLocation: CLLocation(latitude: 34.6937, longitude: 135.5014),  funfacts: funFactsOsaka),
    City(id: 103, city: "Tokyo",            territory: "Japan",                 coreLocation: CLLocation(latitude: 35.6895, longitude: 139.6917),  funfacts: funFactsTokyo),
    City(id: 104, city: "Petra",            territory: "Jordan",                coreLocation: CLLocation(latitude: 30.3285, longitude: 35.4444),   funfacts: funFactsPetra),
    City(id: 105, city: "Kuwait City",      territory: "Kuwait",                coreLocation: CLLocation(latitude: 29.3785, longitude: 47.9903),   funfacts: funFactsKuwaitCity),
    City(id: 106, city: "Antananarivo",     territory: "Madagascar",            coreLocation: CLLocation(latitude: -18.8792, longitude: 47.5079),  funfacts: funFactsAntananarivo),
    City(id: 107, city: "Colima",           territory: "Mexico",                coreLocation: CLLocation(latitude: 19.0598, longitude: -104.2578), funfacts: funFactsColima),
    City(id: 108, city: "Mexico City",      territory: "Mexico",                coreLocation: CLLocation(latitude: 19.4326, longitude: -99.1332),  funfacts: funFactsMexicoCity),
    City(id: 109, city: "Ulaanbaatar",      territory: "Mongolia",              coreLocation: CLLocation(latitude: 47.8864, longitude: 106.9057),  funfacts: funFactsUlaanbaatar),
    City(id: 110, city: "Casablanca",       territory: "Morocco",               coreLocation: CLLocation(latitude: 33.5731, longitude: -7.5898),   funfacts: funFactsCasablanca),
    City(id: 111, city: "Kathmandu",        territory: "Nepal",                 coreLocation: CLLocation(latitude: 27.7172, longitude: 85.3240),   funfacts: funFactsKathmandu),
    City(id: 112, city: "Amsterdam",        territory: "Netherlands",           coreLocation: CLLocation(latitude: 52.3676, longitude: 4.9041),    funfacts: funFactsAmsterdam),
    City(id: 113, city: "Auckland",         territory: "New Zealand",           coreLocation: CLLocation(latitude: -36.8485, longitude: 174.7633), funfacts: funFactsAuckland),
    City(id: 114, city: "Niamey",           territory: "Niger",                 coreLocation: CLLocation(latitude: 13.5116, longitude: 2.1254),    funfacts: funFactsNiamey),
    City(id: 115, city: "Pyongyang",        territory: "North Korea",           coreLocation: CLLocation(latitude: 39.0190, longitude: 125.7543),  funfacts: funFactsPyongyang),
    City(id: 116, city: "Örebro",           territory: "Sweden",                coreLocation: CLLocation(latitude: 59.2753, longitude: 15.2134),   funfacts: funFactsOrebro),
    City(id: 117, city: "Oslo",             territory: "Norway",                coreLocation: CLLocation(latitude: 59.9139, longitude: 10.7522),   funfacts: funFactsOslo),
    City(id: 118, city: "Karachi",          territory: "Pakistan",              coreLocation: CLLocation(latitude: 24.8607, longitude: 67.0011),   funfacts: funFactsKarachi),
    City(id: 119, city: "Panama City",      territory: "Panama",                coreLocation: CLLocation(latitude: 8.9824, longitude: -79.5199),   funfacts: funFactsPanamaCity),
    City(id: 120, city: "Lima",             territory: "Peru",                  coreLocation: CLLocation(latitude: -12.0464, longitude: -77.0428), funfacts: funFactsLima),
    City(id: 121, city: "Davao",            territory: "Philippines",           coreLocation: CLLocation(latitude: 7.1907, longitude: 125.4553),   funfacts: funFactsDavao),
    City(id: 122, city: "Warsaw",           territory: "Poland",                coreLocation: CLLocation(latitude: 52.2297, longitude: 21.0122),   funfacts: funFactsWarsaw),
    City(id: 123, city: "Lisbon",           territory: "Portugal",              coreLocation: CLLocation(latitude: 38.7223, longitude: -9.1393),   funfacts: funFactsLisbon),
    City(id: 124, city: "Moscow",           territory: "Russia",                coreLocation: CLLocation(latitude: 55.7558, longitude: 37.6173),   funfacts: funFactsMoscow),
    City(id: 125, city: "Oymyakon",         territory: "Russia",                coreLocation: CLLocation(latitude: 63.4645, longitude: 142.7840),  funfacts: funFactsOymyakon),
    City(id: 126, city: "Yakutsk",          territory: "Russia",                coreLocation: CLLocation(latitude: 62.0339, longitude: 129.7331),  funfacts: funFactsYakutsk),
    City(id: 127, city: "Mecca",            territory: "Saudi Arabia",          coreLocation: CLLocation(latitude: 21.4224, longitude: 39.8262),   funfacts: funFactsMecca),
    City(id: 128, city: "Riyadh",           territory: "Saudi Arabia",          coreLocation: CLLocation(latitude: 24.7136, longitude: 46.6753),   funfacts: funFactsRiyadh),
    City(id: 129, city: "Edinburgh",        territory: "Scotland",              coreLocation: CLLocation(latitude: 55.9533, longitude: -3.1883),   funfacts: funFactsEdinburgh),
    City(id: 130, city: "Singapore",        territory: "Singapore",             coreLocation: CLLocation(latitude: 1.3521, longitude: 103.8198),   funfacts: funFactsSingapore),
    City(id: 131, city: "Madrid",           territory: "Spain",                 coreLocation: CLLocation(latitude: 40.4168, longitude: -3.7038),   funfacts: funFactsMadrid),
    City(id: 132, city: "Tarragona",        territory: "Spain",                 coreLocation: CLLocation(latitude: 41.1172, longitude: 1.2546),    funfacts: funFactsTarragona),
    City(id: 133, city: "Suva",             territory: "Fiji",                  coreLocation: CLLocation(latitude: -18.1248, longitude: 178.4501), funfacts: funFactsSuva),
    City(id: 134, city: "Aleppo",           territory: "Syria",                 coreLocation: CLLocation(latitude: 36.2021, longitude: 37.1343),   funfacts: funFactsAleppo),
    City(id: 135, city: "Andong",           territory: "South Korea",           coreLocation: CLLocation(latitude: 36.5681, longitude: 128.7298),  funfacts: funFactsAndong),
    City(id: 136, city: "Johannesburg",     territory: "South Africa",          coreLocation: CLLocation(latitude: -26.2041, longitude: 28.0473),  funfacts: funFactsJohannesburg),
    City(id: 137, city: "Zurich",           territory: "Switzerland",           coreLocation: CLLocation(latitude: 47.3769, longitude: 8.5417),    funfacts: funFactsZurich),
    City(id: 138, city: "Taipei",           territory: "Taiwan",                coreLocation: CLLocation(latitude: 25.0330, longitude: 121.5654),  funfacts: funFactsTaipei),
    City(id: 139, city: "Rayong",           territory: "Thailand",              coreLocation: CLLocation(latitude: 12.6800, longitude: 101.2564),  funfacts: funFactsRayong),
    City(id: 140, city: "Istanbul",         territory: "Turkey",                coreLocation: CLLocation(latitude: 41.0082, longitude: 28.9784),   funfacts: funFactsIstanbul),
    City(id: 141, city: "Kampala",          territory: "Uganda",                coreLocation: CLLocation(latitude: 0.3476,  longitude: 32.5825),   funfacts: funFactsKampala),
    City(id: 142, city: "Kyiv",             territory: "Ukraine",               coreLocation: CLLocation(latitude: 50.4501, longitude: 30.5234),   funfacts: funFactsKyiv),
    City(id: 143, city: "Dubai",            territory: "United Arab Emirates",  coreLocation: CLLocation(latitude: 25.2048, longitude: 55.2708),   funfacts: funFactsDubai),
    City(id: 144, city: "London",           territory: "United Kingdom",        coreLocation: CLLocation(latitude: 51.5074, longitude: -0.1278),   funfacts: funFactsLondon),
    City(id: 145, city: "Sana'a",           territory: "Yemen",                 coreLocation: CLLocation(latitude: 15.3547, longitude: 44.2066),   funfacts: funFactsSanaa),
    City(id: 146, city: "Harare",           territory: "Zimbabwe",              coreLocation: CLLocation(latitude: -17.8252, longitude: 31.0335),  funfacts: funFactsHarare)
]
var ALL_CITIES: [City] = CityModes + US_CITIES + WORLD_CITIES

let standAloneCities: [City] = US_CITIES + WORLD_CITIES
let standAloneCities_nostates: [City] = WORLD_CITIES 


