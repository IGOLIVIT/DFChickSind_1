//
//  UserPreferences.swift
//  JourneyCraft
//
//  Created by IGOR on 09/08/2025.
//

import Foundation
import SwiftUI

class UserPreferences: ObservableObject {
    @Published var hasCompletedOnboarding: Bool = false
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var travelStyle: TravelStyle = .balanced
    @Published var interestCategories: Set<InterestCategory> = []
    @Published var preferredTransportation: TransportationType = .mixed
    @Published var ecoFriendlyMode: Bool = true
    @Published var notificationsEnabled: Bool = false
    @Published var locationPermissionGranted: Bool = false
    @Published var favoriteLocationIds: Set<UUID> = Set<UUID>()
    
    enum TravelStyle: String, CaseIterable, Codable {
        case adventure = "Adventure"
        case relaxation = "Relaxation"
        case cultural = "Cultural"
        case balanced = "Balanced"
        
        var icon: String {
            switch self {
            case .adventure: return "mountain.2"
            case .relaxation: return "leaf"
            case .cultural: return "building.columns"
            case .balanced: return "scale.3d"
            }
        }
        
        var description: String {
            switch self {
            case .adventure: return "Thrilling activities and outdoor exploration"
            case .relaxation: return "Peaceful experiences and wellness activities"
            case .cultural: return "Museums, art, and local traditions"
            case .balanced: return "Perfect mix of all travel experiences"
            }
        }
    }
    
    enum InterestCategory: String, CaseIterable, Codable {
        case food = "Food & Dining"
        case nature = "Nature & Parks"
        case history = "History & Heritage"
        case shopping = "Shopping"
        case nightlife = "Nightlife"
        case art = "Art & Museums"
        case sports = "Sports & Recreation"
        case wellness = "Wellness & Spa"
        
        var icon: String {
            switch self {
            case .food: return "fork.knife"
            case .nature: return "tree"
            case .history: return "building.columns"
            case .shopping: return "bag"
            case .nightlife: return "moon.stars"
            case .art: return "paintbrush"
            case .sports: return "figure.run"
            case .wellness: return "heart"
            }
        }
    }
    
    enum TransportationType: String, CaseIterable, Codable {
        case walking = "Walking"
        case cycling = "Cycling"
        case publicTransport = "Public Transport"
        case car = "Car"
        case mixed = "Mixed"
        
        var icon: String {
            switch self {
            case .walking: return "figure.walk"
            case .cycling: return "bicycle"
            case .publicTransport: return "bus"
            case .car: return "car"
            case .mixed: return "location"
            }
        }
        
        var ecoRating: Int {
            switch self {
            case .walking, .cycling: return 5
            case .publicTransport: return 4
            case .mixed: return 3
            case .car: return 2
            }
        }
    }
    
    func savePreferences() {
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(firstName, forKey: "firstName")
        UserDefaults.standard.set(lastName, forKey: "lastName")
        UserDefaults.standard.set(travelStyle.rawValue, forKey: "travelStyle")
        UserDefaults.standard.set(preferredTransportation.rawValue, forKey: "preferredTransportation")
        UserDefaults.standard.set(ecoFriendlyMode, forKey: "ecoFriendlyMode")
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(locationPermissionGranted, forKey: "locationPermissionGranted")
        
        let categoriesArray = Array(interestCategories).map { $0.rawValue }
        UserDefaults.standard.set(categoriesArray, forKey: "interestCategories")
    }
    
    func loadPreferences() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        firstName = UserDefaults.standard.string(forKey: "firstName") ?? ""
        lastName = UserDefaults.standard.string(forKey: "lastName") ?? ""
        
        if let travelStyleString = UserDefaults.standard.string(forKey: "travelStyle"),
           let style = TravelStyle(rawValue: travelStyleString) {
            travelStyle = style
        }
        
        if let transportString = UserDefaults.standard.string(forKey: "preferredTransportation"),
           let transport = TransportationType(rawValue: transportString) {
            preferredTransportation = transport
        }
        
        ecoFriendlyMode = UserDefaults.standard.bool(forKey: "ecoFriendlyMode")
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        locationPermissionGranted = UserDefaults.standard.bool(forKey: "locationPermissionGranted")
        
        if let categoriesArray = UserDefaults.standard.array(forKey: "interestCategories") as? [String] {
            interestCategories = Set(categoriesArray.compactMap { InterestCategory(rawValue: $0) })
        }
        
        if let favoritesData = UserDefaults.standard.data(forKey: "favoriteLocationIds"),
           let favoriteIds = try? JSONDecoder().decode(Set<UUID>.self, from: favoritesData) {
            favoriteLocationIds = favoriteIds
        }
    }
    
    init() {
        loadPreferences()
    }
    
    func addToFavorites(_ locationId: UUID) {
        favoriteLocationIds.insert(locationId)
        saveFavorites()
    }
    
    func removeFromFavorites(_ locationId: UUID) {
        favoriteLocationIds.remove(locationId)
        saveFavorites()
    }
    
    func isFavorite(_ locationId: UUID) -> Bool {
        return favoriteLocationIds.contains(locationId)
    }
    
    private func saveFavorites() {
        if let favoritesData = try? JSONEncoder().encode(favoriteLocationIds) {
            UserDefaults.standard.set(favoritesData, forKey: "favoriteLocationIds")
        }
    }
    
    // MARK: - Account Management
    func resetAllData() {
        // Reset all user data
        hasCompletedOnboarding = false
        firstName = ""
        lastName = ""
        travelStyle = .balanced
        interestCategories = []
        preferredTransportation = .mixed
        ecoFriendlyMode = true
        notificationsEnabled = false
        locationPermissionGranted = false
        favoriteLocationIds = Set<UUID>()
        
        // Clear all UserDefaults data
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: "hasCompletedOnboarding")
        userDefaults.removeObject(forKey: "firstName")
        userDefaults.removeObject(forKey: "lastName")
        userDefaults.removeObject(forKey: "travelStyle")
        userDefaults.removeObject(forKey: "preferredTransportation")
        userDefaults.removeObject(forKey: "ecoFriendlyMode")
        userDefaults.removeObject(forKey: "notificationsEnabled")
        userDefaults.removeObject(forKey: "locationPermissionGranted")
        userDefaults.removeObject(forKey: "interestCategories")
        userDefaults.removeObject(forKey: "favoriteLocationIds")
        userDefaults.synchronize()
    }
}
