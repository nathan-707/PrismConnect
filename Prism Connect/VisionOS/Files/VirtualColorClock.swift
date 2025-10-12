//
//  VirtualColorClock.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 8/29/25.
//

import Combine
import CoreLocation
import Foundation
import WeatherKit

//#if os(visionOS)

class Weather: Equatable {
    var weatherMain: String = ""
    var weatherDescription: String = ""
    var temp_main: Double = 0
    var temp_feelsLike: Double = 0
    var weatherLight: WeatherLight = .UNKNOWN
    var isDayLight: Bool = false
    var intensity: Double = 0

    static func == (lhs: Weather, rhs: Weather) -> Bool {
        return lhs.weatherMain == rhs.weatherMain
            && lhs.weatherDescription == rhs.weatherDescription
            && lhs.temp_main == rhs.temp_main
            && lhs.temp_feelsLike == rhs.temp_feelsLike
            && lhs.weatherLight == rhs.weatherLight
            && lhs.isDayLight == rhs.isDayLight
            && lhs.intensity == rhs.intensity
    }
}



class VirtualColorClock: NSObject, CLLocationManagerDelegate {
    // Tracks when we last successfully fetched weather
    private var lastFetchDate: Date? = nil
    // Default refresh interval in seconds (e.g., 10 minutes)
    private var homeWeatherRefreshInterval: TimeInterval =
        getWeatherInterval_Mins * 60
    private var getTeleportFetchCoolOffInterval: TimeInterval =
        getWeatherInterval_Mins * 60
    private var gotHomeWeather: Bool = false
    var currentWeather = Weather()
    var locationManager: CLLocationManager
    var gotLocation = false
    var homeLocation: CLLocation
    var sessionManager: ClockSessionManager?
    var homeLocationCache = Weather()

    func getWeather(mode: Modes, city: City) async -> Bool {
        // Handle teleport/city mode immediately with the city’s known location.
        if mode != .home {
            let cityLocation = city.coreLocation
            return await fetchWeather(
                using: cityLocation,
                mode: mode,
                teleportCity: city
            )
        }

        // Home mode: ensure we have authorization and a current location.
        let status = currentAuthorizationStatus()

        switch status {
        case .notDetermined:
            print(
                "Location auth not determined. Requesting When-In-Use authorization…"
            )
            locationManager.requestWhenInUseAuthorization()
            return false

        case .authorizedWhenInUse, .authorizedAlways:
            if gotLocation {
                return await fetchWeather(
                    using: homeLocation,
                    mode: mode,
                    teleportCity: city
                )
            } else {
                print("No home location. Retrying to get it...")
                locationManager.requestLocation()
                return false
            }

        case .denied, .restricted:
            print(
                "Location access denied or restricted; cannot fetch home weather."
            )
            Task { @MainActor in
                sessionManager?.locationDenied = true
            }
            return false

        @unknown default:
            print("Unknown authorization status.")
            return false
        }
    }

    @MainActor
    private func fetchWeather(
        using location: CLLocation,
        mode: Modes,
        teleportCity: City
    ) async -> Bool {
        do {
            // Respect a minimum refresh interval if we recently fetched
            if mode == .home {
                if let last = lastFetchDate {
                    let elapsed = Date().timeIntervalSince(last)
                    if elapsed < homeWeatherRefreshInterval {
                        print(
                            "Skipping weather fetch; only \(Int(elapsed))s elapsed (< \(Int(homeWeatherRefreshInterval))s interval)"
                        )
                        sessionManager?.isDay = homeLocationCache.isDayLight
                        currentWeather.isDayLight = homeLocationCache.isDayLight
                        currentWeather.intensity = homeLocationCache.intensity
                        currentWeather.temp_main = homeLocationCache.temp_main
                        currentWeather.temp_feelsLike =
                            homeLocationCache.temp_feelsLike
                        currentWeather.weatherDescription =
                            homeLocationCache.weatherDescription
                        currentWeather.weatherMain =
                            homeLocationCache.weatherMain
                        currentWeather.weatherLight =
                            homeLocationCache.weatherLight
                        return true
                    }
                }
            } else {  // teleporting.
                if let lastTeleportCityDate = teleportCity.lastWeatherFetch {
                    let elapsed = Date().timeIntervalSince(lastTeleportCityDate)
                    if elapsed < getTeleportFetchCoolOffInterval {
                        print(
                            "Skipping weather fetch for \(teleportCity.city); only \(Int(elapsed))s elapsed (< \(Int(getTeleportFetchCoolOffInterval))s interval)"
                        )
                        let weatherCache = teleportCity.weatherCache

                        // set current weather to the citys weather cache.
                        sessionManager?.isDay = weatherCache.isDayLight
                        currentWeather.isDayLight = weatherCache.isDayLight
                        currentWeather.intensity = weatherCache.intensity
                        currentWeather.temp_main = weatherCache.temp_main
                        currentWeather.temp_feelsLike =
                            weatherCache.temp_feelsLike
                        currentWeather.weatherDescription =
                            weatherCache.weatherDescription
                        currentWeather.weatherMain = weatherCache.weatherMain
                        currentWeather.weatherLight = weatherCache.weatherLight
                        return true
                    }
                }
            }

            // teleporting if here.
            print(
                "attempting weather for \(location.coordinate.latitude) \(location.coordinate.longitude)"
            )
            let service = WeatherService.shared
            let weather = try await service.weather(for: location)
            sessionManager?.isDay = weather.currentWeather.isDaylight
            self.currentWeather.isDayLight = weather.currentWeather.isDaylight
            self.currentWeather.intensity =
                weather.currentWeather.precipitationIntensity.value
            self.currentWeather.temp_main =
                weather.currentWeather.temperature.converted(to: .fahrenheit)
                .value
            self.currentWeather.temp_feelsLike =
                weather.currentWeather.apparentTemperature.converted(
                    to: .fahrenheit
                ).value
            self.currentWeather.weatherDescription =
                weather.currentWeather.condition.description

            let (weatherLight, metaWeatherDescription) = determineWeatherLight(
                weatherMain: weather.currentWeather.condition.description,
                cloudCover: weather.currentWeather.cloudCover,
                precipitationIntensity: weather.currentWeather
                    .precipitationIntensity.value,
                daytime: weather.currentWeather.isDaylight
            )

            self.currentWeather.weatherMain = metaWeatherDescription
            self.currentWeather.weatherLight = weatherLight

            if mode == .home {  // update home weather cache and interval
                self.lastFetchDate = Date()
                sessionManager?.initHomeWeather = true
                sessionManager?.isDay = currentWeather.isDayLight
                homeLocationCache.isDayLight = currentWeather.isDayLight
                homeLocationCache.intensity = currentWeather.intensity
                homeLocationCache.temp_main = currentWeather.temp_main
                homeLocationCache.temp_feelsLike = currentWeather.temp_feelsLike
                homeLocationCache.weatherDescription =
                    currentWeather.weatherDescription
                homeLocationCache.weatherMain = currentWeather.weatherMain
                homeLocationCache.weatherLight = currentWeather.weatherLight
            } else {  // update teleport cities weather cache and interval
                // Update the matched city's lastWeatherFetch by index (requires ALL_CITIES to be a mutable array)
                if let idx = ALL_CITIES.firstIndex(where: {
                    $0.nameForPicker() == teleportCity.nameForPicker()
                }) {
                    ALL_CITIES[idx].lastWeatherFetch = Date()
                    ALL_CITIES[idx].weatherCache.isDayLight =
                        currentWeather.isDayLight
                    ALL_CITIES[idx].weatherCache.intensity =
                        currentWeather.intensity
                    ALL_CITIES[idx].weatherCache.temp_main =
                        currentWeather.temp_main
                    ALL_CITIES[idx].weatherCache.temp_feelsLike =
                        currentWeather.temp_feelsLike
                    ALL_CITIES[idx].weatherCache.weatherDescription =
                        currentWeather.weatherDescription
                    ALL_CITIES[idx].weatherCache.weatherMain =
                        currentWeather.weatherMain
                    ALL_CITIES[idx].weatherCache.weatherLight =
                        currentWeather.weatherLight
                }
            }

            lastWorldTourSuccessFetchDate = Date()
            lastHomeSuccessFetchDate = Date()
            print("WEATHER SUCCESS")
            sessionManager?.reportWeatherError = false
            return true
        } catch {
            print("WeatherKit fetch failed: \(error.localizedDescription)")
            sessionManager?.reportWeatherError = true
            
            if sessionManager?.isStandaloneMode == true && sessionManager?.standalonemode_Mode == .teleportMode {
                sessionManager?.standalonemode_Mode = .home
                
            }
            
            return false
        }
    }

    override init() {
        homeLocation = CLLocation(latitude: 0, longitude: 0)
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    // MARK: - CLLocationManagerDelegate
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.first else { return }
        gotLocation = true
        homeLocation = CLLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        print(
            "Got home location: \(homeLocation.coordinate.latitude), \(homeLocation.coordinate.longitude)"
        )
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        print("CLLocationManager error: \(error.localizedDescription)")
    }
    // iOS 14+/visionOS authorization change callback.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = currentAuthorizationStatus()
        switch status {
        case .notDetermined:
            // Do nothing; waiting for the system to prompt.
            break
        case .authorizedWhenInUse, .authorizedAlways:
            print("Authorized; requesting location…")
            manager.requestLocation()
        case .denied, .restricted:
            print("Authorization denied/restricted.")
        @unknown default:
            print("Unknown authorization status.")
        }
    }
    // MARK: - Helpers
    private func currentAuthorizationStatus() -> CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return locationManager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }
}

//#endif
