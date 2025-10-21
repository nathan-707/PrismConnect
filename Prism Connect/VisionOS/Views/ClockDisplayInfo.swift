//
//  ClockDisplayInfo.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 9/2/25.
//

import CoreLocation
import Foundation
import MapKit
import Network
import SwiftUI

#if os(visionOS)

    struct ClockDisplayInfo: View {
        @State var currentDate = Date()
        @State var clockTime: String = "1:00"
        @State private var timer: Timer? = nil
        @State var localFunfact = "sugma"
        @State var userZipCode: String = ""
        private var isZipValid: Bool {
            userZipCode.count == 5 && userZipCode.allSatisfy({ $0.isNumber })
        }
        @EnvironmentObject private var prismSessionManager: ClockSessionManager
        @State private var isConnectedToInternet: Bool = true
        private let networkMonitor = NWPathMonitor()
        private let networkQueue = DispatchQueue(
            label: "ClockDisplayInfo.NetworkMonitor"
        )
        private var formattedTime: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm  a"  // This ensures a space before AM/PM
            return formatter.string(from: currentDate)
        }

        var body: some View {
            VStack {
                if prismSessionManager.initHomeWeather {
                    if prismSessionManager.isStandaloneMode == false
                        && prismSessionManager.pending
                    {
                        ProgressView()
                    } else {
                        VisionClockInfoView()
                    }
                } else {

                    if prismSessionManager.locationDenied
                        || debug.locationDenied_Test
                    {
                        Text("Allow Location in Settings for Weather.")
                    } else if !isConnectedToInternet || debug.noInternet_Test {
                        Text("You are not connected to the internet.")
                    }

                    // TODO: IN the future make it where if get location fails ask user to put in zip and then
                    // update the virtual color clock to use it.

                    else if prismSessionManager.failedGetHomeWeatherAttempts > 5
                    {
                        VStack(spacing: 12) {
                            Text(
                                "Could not get current location. Enter Home ZipCode"
                            )
                            TextField(
                                "ZIP Code",
                                text: Binding(
                                    get: { userZipCode },
                                    set: { newValue in
                                        // Allow only digits and cap at 5 characters
                                        let filtered = newValue.filter {
                                            $0.isNumber
                                        }
                                        userZipCode = String(filtered.prefix(5))
                                    }
                                )
                            )
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .frame(maxWidth: 240)

                            Button {
                                prismSessionManager
                                    .failedGetHomeWeatherAttempts = 0
                                Task {
                                    // Safe to force unwrap to Int since validated as 5 digits
                                    if let zipInt = Int(userZipCode) {
                                        await printUserCoordinatesFromZip(
                                            zipcode: zipInt
                                        )
                                    }
                                }
                            } label: {
                                Text("Get Weather")
                            }
                            .disabled(!isZipValid)
                        }
                    } else {
                        ProgressView()
                    }
                }
            }
            .onAppear {
                // Start monitoring network connectivity
                networkMonitor.pathUpdateHandler = { path in
                    let connected = (path.status == .satisfied)
                    DispatchQueue.main.async {
                        self.isConnectedToInternet = connected
                    }
                }
                networkMonitor.start(queue: networkQueue)
            }
            .onChange(
                of: prismSessionManager.CurrentTeleportation,
                { oldValue, newValue in
                    //            localFunfact = prismSessionManager.CurrentTeleportation.funfacts.randomElement() ?? "No fun fact available"
                }
            )
            .onDisappear {
                timer?.invalidate()
                timer = nil
                networkMonitor.cancel()
            }
        }

        @MainActor
        func printUserCoordinatesFromZip(zipcode: Int) async {
            let zipString = String(zipcode)
            let query = "\(zipString), USA"

            // Build a local search request using natural language query
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            // Optionally, bias search to the United States by providing a wide region
            request.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: 39.8283,
                    longitude: -98.5795
                ),  // Approx center of contiguous US
                span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 60)
            )

            let search = MKLocalSearch(request: request)

            do {
                let response = try await search.start()
                if let item = response.mapItems.first,
                    let location = item.placemark.location
                {
                    let coord = location.coordinate
                    print(
                        "Coordinates for ZIP \(zipString): lat=\(coord.latitude), lon=\(coord.longitude)"
                    )
                    print("::::::::MANUALLY SET HOME LOCATION:::::")
                    prismSessionManager.virtualClock?.sessionManager?
                        .initHomeWeather = true
                    prismSessionManager.virtualClock?.gotLocation = true
                    prismSessionManager.virtualClock?.homeLocation = CLLocation(
                        latitude: coord.latitude,
                        longitude: coord.longitude
                    )

                } else {
                    print(
                        "printUserCoordinatesFromZip: No results found for ZIP \(zipString)"
                    )
                }

            } catch {
                print(
                    "printUserCoordinatesFromZip: MapKit search failed for ZIP \(zipString) with error: \(error)"
                )
            }
        }
    }
#endif
