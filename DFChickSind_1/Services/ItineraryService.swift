//
//  ItineraryService.swift
//  JourneyCraft
//
//  Created by IGOR on 09/08/2025.
//

import Foundation
import Combine
import CoreLocation

class ItineraryService: ObservableObject {
    @Published var itineraries: [Itinerary] = []
    @Published var currentItinerary: Itinerary?
    
    private let userDefaults = UserDefaults.standard
    private let itinerariesKey = "saved_itineraries"
    
    init() {
        loadItineraries()
    }
    
    // MARK: - CRUD Operations
    func updateItinerary(_ itinerary: Itinerary) {
        if let index = itineraries.firstIndex(where: { $0.id == itinerary.id }) {
            itineraries[index] = itinerary
            saveItineraries()
        }
    }
    
    func deleteItinerary(_ itinerary: Itinerary) {
        itineraries.removeAll { $0.id == itinerary.id }
        if currentItinerary?.id == itinerary.id {
            currentItinerary = nil
        }
        saveItineraries()
    }
    
    func duplicateItinerary(_ itinerary: Itinerary) {
        var duplicated = itinerary
        duplicated.title += " (Copy)"
        duplicated.createdAt = Date()
        duplicated.updatedAt = Date()
        addItinerary(duplicated)
    }
    
    // MARK: - Smart Itinerary Generation
    func generateSmartItinerary(
        title: String,
        startDate: Date,
        endDate: Date,
        startLocation: CLLocationCoordinate2D,
        preferences: UserPreferences,
        locationService: LocationService
    ) -> Itinerary {
        print("🏗️ ItineraryService.generateSmartItinerary called for: '\(title)'")
        
        let duration = endDate.timeIntervalSince(startDate)
        let days = Int(duration / 86400) + 1
        print("📅 Trip duration: \(days) days")
        
        var destinations: [JCLocation] = []
        
        // Generate destinations based on preferences
        for day in 0..<days {
            print("📍 Generating destinations for day \(day + 1)...")
            let dayDestinations = generateDestinationsForDay(
                day: day,
                around: startLocation,
                preferences: preferences,
                locationService: locationService
            )
            print("📍 Generated \(dayDestinations.count) destinations for day \(day + 1)")
            destinations.append(contentsOf: dayDestinations)
        }
        
        print("🎯 Total destinations generated: \(destinations.count)")
        
        let itinerary = Itinerary(
            title: title,
            description: generateItineraryDescription(preferences: preferences, destinations: destinations),
            destinations: destinations,
            startDate: startDate,
            endDate: endDate,
            travelStyle: preferences.travelStyle,
            tags: generateTags(for: preferences, destinations: destinations)
        )
        
        return itinerary
    }
    
    private func generateDestinationsForDay(
        day: Int,
        around coordinate: CLLocationCoordinate2D,
        preferences: UserPreferences,
        locationService: LocationService
    ) -> [JCLocation] {
        print("🌅 generateDestinationsForDay \(day + 1) around (\(coordinate.latitude), \(coordinate.longitude))")
        var destinations: [JCLocation] = []
        let maxDestinationsPerDay = 4
        
        // Morning activity
        if let morningActivity = selectActivity(
            for: .morning,
            preferences: preferences,
            around: coordinate,
            locationService: locationService
        ) {
            destinations.append(morningActivity)
        }
        
        // Lunch spot
        if destinations.count < maxDestinationsPerDay,
           let lunchSpot = selectActivity(
            for: .lunch,
            preferences: preferences,
            around: coordinate,
            locationService: locationService
           ) {
            destinations.append(lunchSpot)
        }
        
        // Afternoon activity
        if destinations.count < maxDestinationsPerDay,
           let afternoonActivity = selectActivity(
            for: .afternoon,
            preferences: preferences,
            around: coordinate,
            locationService: locationService
           ) {
            destinations.append(afternoonActivity)
        }
        
        // Evening activity (optional)
        if destinations.count < maxDestinationsPerDay,
           preferences.interestCategories.contains(.nightlife),
           let eveningActivity = selectActivity(
            for: .evening,
            preferences: preferences,
            around: coordinate,
            locationService: locationService
           ) {
            destinations.append(eveningActivity)
        }
        
        return destinations
    }
    
    private enum TimeOfDay {
        case morning, lunch, afternoon, evening
    }
    
    private func selectActivity(
        for timeOfDay: TimeOfDay,
        preferences: UserPreferences,
        around coordinate: CLLocationCoordinate2D,
        locationService: LocationService
    ) -> JCLocation? {
        let preferredCategories = getPreferredCategories(for: timeOfDay, preferences: preferences)
        
        for category in preferredCategories {
            let locations = locationService.searchNearbyLocations(category: category, radius: 10000)
            let filteredLocations = filterLocationsByPreferences(locations, preferences: preferences)
            
            if let selectedLocation = filteredLocations.randomElement() {
                return selectedLocation
            }
        }
        
        return nil
    }
    
    private func getPreferredCategories(for timeOfDay: TimeOfDay, preferences: UserPreferences) -> [JCLocation.LocationCategory] {
        switch timeOfDay {
        case .morning:
            var categories: [JCLocation.LocationCategory] = []
            if preferences.interestCategories.contains(.nature) { categories.append(.nature) }
            if preferences.interestCategories.contains(.wellness) { categories.append(.wellness) }
            if preferences.interestCategories.contains(.art) { categories.append(.museum) }
            if categories.isEmpty { categories = [.nature, .museum, .attraction] }
            return categories
            
        case .lunch:
            return [.restaurant]
            
        case .afternoon:
            var categories: [JCLocation.LocationCategory] = []
            if preferences.interestCategories.contains(.shopping) { categories.append(.shopping) }
            if preferences.interestCategories.contains(.history) { categories.append(.museum) }
            if preferences.interestCategories.contains(.art) { categories.append(.museum) }
            if categories.isEmpty { categories = [.attraction, .shopping, .museum] }
            return categories
            
        case .evening:
            var categories: [JCLocation.LocationCategory] = []
            if preferences.interestCategories.contains(.nightlife) { categories.append(.entertainment) }
            if preferences.interestCategories.contains(.food) { categories.append(.restaurant) }
            if categories.isEmpty { categories = [.entertainment, .restaurant] }
            return categories
        }
    }
    
    private func filterLocationsByPreferences(_ locations: [JCLocation], preferences: UserPreferences) -> [JCLocation] {
        return locations.filter { location in
            // Filter by eco-friendly preference
            if preferences.ecoFriendlyMode && !location.isEcoFriendly {
                return false
            }
            
            // Filter by travel style
            switch preferences.travelStyle {
            case .adventure:
                return location.category == .nature || location.category == .attraction
            case .relaxation:
                return location.category == .wellness || location.category == .nature
            case .cultural:
                return location.category == .museum || location.category == .attraction
            case .balanced:
                return true // Accept all categories for balanced style
            }
        }
    }
    
    private func generateItineraryDescription(preferences: UserPreferences, destinations: [JCLocation]) -> String {
        let styleDescription = preferences.travelStyle.description
        let destinationCount = destinations.count
        let categories = Set(destinations.map { $0.category.rawValue }).joined(separator: ", ")
        
        return "A \(preferences.travelStyle.rawValue.lowercased()) journey featuring \(destinationCount) carefully selected destinations including \(categories). \(styleDescription)"
    }
    
    private func generateTags(for preferences: UserPreferences, destinations: [JCLocation]) -> [String] {
        var tags: [String] = [preferences.travelStyle.rawValue.lowercased()]
        
        if preferences.ecoFriendlyMode {
            tags.append("eco-friendly")
        }
        
        let categoryTags = Set(destinations.map { $0.category.rawValue.lowercased() })
        tags.append(contentsOf: categoryTags)
        
        let interestTags = preferences.interestCategories.map { $0.rawValue.lowercased() }
        tags.append(contentsOf: interestTags)
        
        return Array(Set(tags)) // Remove duplicates
    }
    
    // MARK: - Optimization
    func optimizeItinerary(_ itinerary: Itinerary) -> Itinerary {
        var optimized = itinerary
        
        // Sort destinations by geographic proximity for efficient travel
        optimized.destinations = optimizeDestinationOrder(optimized.destinations)
        optimized.updateCalculatedProperties()
        
        return optimized
    }
    
    private func optimizeDestinationOrder(_ destinations: [JCLocation]) -> [JCLocation] {
        guard destinations.count > 2 else { return destinations }
        
        var optimized: [JCLocation] = []
        var remaining = destinations
        
        // Start with the first destination
        if let first = remaining.first {
            optimized.append(first)
            remaining.removeFirst()
        }
        
        // Add nearest destinations iteratively
        while !remaining.isEmpty {
            guard let current = optimized.last else { break }
            
            let nearest = remaining.min { location1, location2 in
                let distance1 = current.distance(from: CLLocation(latitude: location1.coordinate.latitude, 
                                                                 longitude: location1.coordinate.longitude))
                let distance2 = current.distance(from: CLLocation(latitude: location2.coordinate.latitude, 
                                                                 longitude: location2.coordinate.longitude))
                return distance1 < distance2
            }
            
            if let nearest = nearest {
                optimized.append(nearest)
                remaining.removeAll { $0.id == nearest.id }
            }
        }
        
        return optimized
    }
    
    // MARK: - Persistence
    private func saveItineraries() {
        do {
            let data = try JSONEncoder().encode(itineraries)
            userDefaults.set(data, forKey: itinerariesKey)
            userDefaults.synchronize()
        } catch {
            print("Failed to save itineraries: \(error)")
        }
    }
    
    private func loadItineraries() {
        guard let data = userDefaults.data(forKey: itinerariesKey) else { 
            return 
        }
        
        do {
            itineraries = try JSONDecoder().decode([Itinerary].self, from: data)
        } catch {
            print("Failed to load itineraries: \(error)")
            itineraries = []
        }
    }
    
    // MARK: - Search and Filter
    func searchItineraries(_ query: String) -> [Itinerary] {
        guard !query.isEmpty else { return itineraries }
        
        return itineraries.filter { itinerary in
            itinerary.title.localizedCaseInsensitiveContains(query) ||
            itinerary.description.localizedCaseInsensitiveContains(query) ||
            itinerary.tags.contains { $0.localizedCaseInsensitiveContains(query) } ||
            itinerary.destinations.contains { $0.name.localizedCaseInsensitiveContains(query) }
        }
    }
    
    func filterItineraries(by style: UserPreferences.TravelStyle?) -> [Itinerary] {
        guard let style = style else { return itineraries }
        return itineraries.filter { $0.travelStyle == style }
    }
    
    func getEcoFriendlyItineraries() -> [Itinerary] {
        return itineraries.filter { $0.isEcoFriendly }
    }
    
    func addItinerary(_ itinerary: Itinerary) {
        itineraries.append(itinerary)
        saveItineraries()
    }
    
    // MARK: - Data Management
    func clearAllData() {
        itineraries.removeAll()
        currentItinerary = nil
        userDefaults.removeObject(forKey: itinerariesKey)
        userDefaults.synchronize()
    }
}
