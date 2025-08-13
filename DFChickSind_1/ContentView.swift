//
//  ContentView.swift
//  JourneyCraft
//
//  Created by IGOR on 09/08/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var userPreferences: UserPreferences
    @EnvironmentObject private var locationService: LocationService
    @StateObject private var itineraryService: ItineraryService
    @StateObject private var navigationService: NavigationService
    @StateObject private var itineraryViewModel: ItineraryViewModel
    @StateObject private var navigationViewModel: NavigationViewModel
    
    init() {
        let locationSvc = LocationService()
        let navigationSvc = NavigationService(locationService: locationSvc)
        let itinerarySvc = ItineraryService()
        
        _itineraryService = StateObject(wrappedValue: itinerarySvc)
        _navigationService = StateObject(wrappedValue: navigationSvc)
        _itineraryViewModel = StateObject(wrappedValue: ItineraryViewModel(itineraryService: itinerarySvc, locationService: locationSvc))
        _navigationViewModel = StateObject(wrappedValue: NavigationViewModel(navigationService: navigationSvc, locationService: locationSvc))
    }
    
    var body: some View {
        Group {
            if userPreferences.hasCompletedOnboarding {
                MainTabViewWrapper()
                    .environmentObject(itineraryService)
                    .environmentObject(navigationService)
                    .environmentObject(itineraryViewModel)
                    .environmentObject(navigationViewModel)
            } else {
                OnboardingView()
            }
        }
        .onAppear {
            userPreferences.loadPreferences()
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var userPreferences: UserPreferences
    @EnvironmentObject private var itineraryViewModel: ItineraryViewModel
    @EnvironmentObject private var navigationViewModel: NavigationViewModel
    @EnvironmentObject private var exploreViewModel: ExploreViewModel
    
    var body: some View {
        TabView {
            // Itinerary Tab
            ItineraryView()
                .tabItem {
                    Image(systemName: "list.bullet.circle")
                    Text("Itinerary")
                }
                .environmentObject(itineraryViewModel)
            
            // Explore Tab
            ExploreView()
                .tabItem {
                    Image(systemName: "star.circle")
                    Text("Explore")
                }
                .environmentObject(exploreViewModel)
                .environmentObject(itineraryViewModel)
            
            // Navigation Tab
            NavigationAlertsView()
                .tabItem {
                    Image(systemName: "bell.circle")
                    Text("Alerts")
                }
                .environmentObject(navigationViewModel)
            
            // Map Tab
            NavigationMapView()
                .tabItem {
                    Image(systemName: "map.circle")
                    Text("Map")
                }
                .environmentObject(navigationViewModel)
        }
        .accentColor(Color(hex: "#fcc418"))
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(hex: "#3e4464"))
        
        // Normal state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.6)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.6),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: "#fcc418"))
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color(hex: "#fcc418")),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

struct MainTabViewWrapper: View {
    @EnvironmentObject private var userPreferences: UserPreferences
    @EnvironmentObject private var locationService: LocationService
    @StateObject private var exploreViewModel: ExploreViewModel
    
    init() {
        // Temporary initialization - will be updated in onAppear
        _exploreViewModel = StateObject(wrappedValue: ExploreViewModel(locationService: LocationService(), userPreferences: UserPreferences()))
    }
    
    var body: some View {
        MainTabView()
            .environmentObject(exploreViewModel)
            .onAppear {
                // Update ExploreViewModel with proper dependencies
                exploreViewModel.updateDependencies(locationService: locationService, userPreferences: userPreferences)
            }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserPreferences())
        .environmentObject(LocationService())
}
