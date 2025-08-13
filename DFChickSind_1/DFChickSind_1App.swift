//
//  JourneyCraftApp.swift
//  JourneyCraft
//
//  Created by IGOR on 09/08/2025.
//

import SwiftUI

@main
struct JourneyCraftApp: App {
    @StateObject private var locationService = LocationService()
    @StateObject private var userPreferences = UserPreferences()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationService)
                .environmentObject(userPreferences)
        }
    }
}
