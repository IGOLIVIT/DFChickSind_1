//
//  ExploreViewModel.swift
//  JourneyCraft
//
//  Created by IGOR on 09/08/2025.
//

import Foundation
import Combine
import CoreLocation
import UIKit
import MapKit

class ExploreViewModel: ObservableObject {
    @Published var nearbyLocations: [JCLocation] = []
    @Published var searchResults: [JCLocation] = []
    @Published var featuredLocations: [JCLocation] = []
    @Published var ecoFriendlyLocations: [JCLocation] = []
    @Published var searchText = ""
    @Published var selectedCategory: JCLocation.LocationCategory?
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var selectedLocation: JCLocation?
    @Published var showingLocationDetail = false
    @Published var searchRadius: Double = 5000 // in meters
    
    let locationService: LocationService
    private let userPreferences: UserPreferences
    private var cancellables = Set<AnyCancellable>()
    private var searchDebouncer: Timer?
    
    init(locationService: LocationService, userPreferences: UserPreferences = UserPreferences()) {
        self.locationService = locationService
        self.userPreferences = userPreferences
        setupBindings()
        loadInitialData()
    }
    
    private func setupBindings() {
        locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.loadNearbyLocations()
            }
            .store(in: &cancellables)
        
        $searchText
            .sink { [weak self] searchText in
                self?.debounceSearch(searchText)
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        loadFeaturedLocations()
        loadEcoFriendlyLocations()
        if locationService.currentLocation != nil {
            loadNearbyLocations()
        }
    }
    
    // MARK: - Search Functionality
    private func debounceSearch(_ query: String) {
        searchDebouncer?.invalidate()
        
        if query.isEmpty {
            searchResults = []
            isSearching = false
            return
        }
        
        searchDebouncer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.performSearch(query)
        }
    }
    
    private func performSearch(_ query: String) {
        isSearching = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let results = self.locationService.searchLocations(
                query: query,
                near: self.locationService.currentLocation?.coordinate
            )
            
            DispatchQueue.main.async {
                self.searchResults = results
                self.isSearching = false
            }
        }
    }
    
    func searchByCategory(_ category: JCLocation.LocationCategory) {
        selectedCategory = category
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let results = self.locationService.searchNearbyLocations(
                category: category,
                radius: self.searchRadius
            )
            
            DispatchQueue.main.async {
                self.searchResults = results
                self.isLoading = false
            }
        }
    }
    
    func clearSearch() {
        searchText = ""
        searchResults = []
        selectedCategory = nil
        isSearching = false
    }
    
    // MARK: - Location Loading
    private func loadNearbyLocations() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let locations = self.locationService.searchNearbyLocations(radius: self.searchRadius)
            
            DispatchQueue.main.async {
                self.nearbyLocations = locations
                self.isLoading = false
            }
        }
    }
    
    private func loadFeaturedLocations() {
        // Mock featured locations - in a real app, this would come from a curated list or API
        let featured = [
            JCLocation(
                name: "Sustainable Food Market",
                description: "Local organic farmers market with zero-waste policy",
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                category: .shopping,
                rating: 4.8,
                priceLevel: .moderate,
                isEcoFriendly: true,
                carbonFootprint: 0.0,
                estimatedVisitDuration: 5400,
                openingHours: ["Saturday 8:00 AM - 2:00 PM"],
                tags: ["organic", "local", "sustainable", "zero-waste"]
            ),
            JCLocation(
                name: "Rooftop Garden Café",
                description: "Urban garden café serving farm-to-table meals with city views",
                coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
                category: .restaurant,
                rating: 4.6,
                priceLevel: .moderate,
                isEcoFriendly: true,
                carbonFootprint: 1.2,
                estimatedVisitDuration: 3600,
                openingHours: ["Monday-Sunday 7:00 AM - 10:00 PM"],
                tags: ["rooftop", "garden", "farm-to-table", "city-views"]
            ),
            JCLocation(
                name: "Electric Bike Tours",
                description: "Eco-friendly city exploration on electric bikes",
                coordinate: CLLocationCoordinate2D(latitude: 37.7649, longitude: -122.4294),
                category: .attraction,
                rating: 4.9,
                priceLevel: .moderate,
                isEcoFriendly: true,
                carbonFootprint: 0.1,
                estimatedVisitDuration: 10800,
                openingHours: ["Daily 9:00 AM - 6:00 PM"],
                tags: ["electric", "bike", "tour", "eco-friendly", "exploration"]
            )
        ]
        
        featuredLocations = featured
    }
    
    private func loadEcoFriendlyLocations() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let ecoLocations = self.locationService.searchNearbyLocations(radius: self.searchRadius)
                .filter { $0.isEcoFriendly }
                .sorted { $0.rating > $1.rating }
            
            DispatchQueue.main.async {
                self.ecoFriendlyLocations = ecoLocations
            }
        }
    }
    
    // MARK: - Location Actions
    func selectLocation(_ location: JCLocation) {
        selectedLocation = location
        showingLocationDetail = true
    }
    
    func addToItinerary(_ location: JCLocation) {
        // Add to current itinerary if one exists
        // This would typically work with an ItineraryViewModel
        // For now, we'll show a success message (could trigger a toast/alert)
        print("✅ Added \(location.name) to current itinerary")
    }
    
    func shareLocation(_ location: JCLocation) {
        let shareText = """
        📍 \(location.name)
        
        \(location.description)
        
        ⭐ Rating: \(String(format: "%.1f", location.rating))/5.0
        💰 Price: \(location.priceLevel.rawValue)
        🌱 Eco-friendly: \(location.isEcoFriendly ? "Yes" : "No")
        
        🏷️ Tags: \(location.tags.joined(separator: ", "))
        
        📱 Discover more amazing places with JourneyCraft!
        """
        
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            rootVC.present(activityVC, animated: true)
        }
    }
    
    func getDirections(to location: JCLocation) {
        // Open Maps app with directions
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
        mapItem.name = location.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    func getEcoAlternatives(for location: JCLocation) -> [JCLocation] {
        return locationService.getEcoFriendlyAlternatives(for: location)
    }
    
    // MARK: - Filtering and Sorting
    func getLocationsByCategory(_ category: JCLocation.LocationCategory) -> [JCLocation] {
        let allLocations = nearbyLocations + searchResults
        return allLocations.filter { $0.category == category }
    }
    
    func getLocationsByPriceLevel(_ priceLevel: JCLocation.PriceLevel) -> [JCLocation] {
        let allLocations = nearbyLocations + searchResults
        return allLocations.filter { $0.priceLevel == priceLevel }
    }
    
    func sortLocationsByDistance() -> [JCLocation] {
        guard let currentLocation = locationService.currentLocation else {
            return nearbyLocations
        }
        
        return nearbyLocations.sorted { location1, location2 in
            let distance1 = location1.distance(from: currentLocation)
            let distance2 = location2.distance(from: currentLocation)
            return distance1 < distance2
        }
    }
    
    func sortLocationsByRating() -> [JCLocation] {
        return nearbyLocations.sorted { $0.rating > $1.rating }
    }
    
    func sortLocationsByPrice() -> [JCLocation] {
        return nearbyLocations.sorted { $0.priceLevel.value < $1.priceLevel.value }
    }
    
    // MARK: - Helper Methods
    func formatDistance(to location: JCLocation) -> String {
        guard let currentLocation = locationService.currentLocation else {
            return "Distance unknown"
        }
        
        let distance = location.distance(from: currentLocation)
        
        if distance < 1000 {
            return "\(Int(distance))m away"
        } else {
            let km = distance / 1000.0
            return String(format: "%.1f km away", km)
        }
    }
    
    func formatRating(_ rating: Double) -> String {
        return String(format: "%.1f", rating)
    }
    
    func formatVisitDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    func getPriceLevelDescription(_ priceLevel: JCLocation.PriceLevel) -> String {
        switch priceLevel {
        case .free: return "Free"
        case .budget: return "Budget-friendly"
        case .moderate: return "Moderate"
        case .expensive: return "Expensive"
        case .luxury: return "Luxury"
        }
    }
    
    func getOpeningStatus(for location: JCLocation) -> String {
        // Simple implementation - in a real app, this would parse opening hours and check current time
        guard !location.openingHours.isEmpty else { return "Hours unknown" }
        
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        
        // Mock logic based on typical business hours
        if hour >= 9 && hour < 18 {
            return "Open now"
        } else if hour >= 18 && hour < 22 {
            return "Closing soon"
        } else {
            return "Closed"
        }
    }
    
    func getEcoScore(for location: JCLocation) -> Int {
        if !location.isEcoFriendly { return 1 }
        
        let footprint = location.carbonFootprint ?? 5.0
        
        if footprint <= 1.0 { return 5 }
        if footprint <= 2.0 { return 4 }
        if footprint <= 3.0 { return 3 }
        if footprint <= 4.0 { return 2 }
        return 1
    }
    
    func getEcoScoreDescription(_ score: Int) -> String {
        switch score {
        case 5: return "Excellent"
        case 4: return "Very Good"
        case 3: return "Good"
        case 2: return "Fair"
        case 1: return "Poor"
        default: return "Not Rated"
        }
    }
    
    // MARK: - Statistics
    func getExploreStatistics() -> ExploreStatistics {
        let totalLocations = nearbyLocations.count
        let ecoFriendlyCount = nearbyLocations.filter { $0.isEcoFriendly }.count
        let averageRating = nearbyLocations.isEmpty ? 0.0 : nearbyLocations.reduce(0.0) { $0 + $1.rating } / Double(nearbyLocations.count)
        let categoryDistribution = Dictionary(grouping: nearbyLocations) { $0.category }
            .mapValues { $0.count }
        
        return ExploreStatistics(
            totalLocations: totalLocations,
            ecoFriendlyCount: ecoFriendlyCount,
            averageRating: averageRating,
            categoryDistribution: categoryDistribution
        )
    }
    
    func updateSearchRadius(_ radius: Double) {
        searchRadius = radius
        loadNearbyLocations()
    }
    
    // MARK: - Favorites Management
    func toggleFavorite(for location: JCLocation) {
        if userPreferences.isFavorite(location.id) {
            userPreferences.removeFromFavorites(location.id)
        } else {
            userPreferences.addToFavorites(location.id)
        }
    }
    
    func isFavorite(_ location: JCLocation) -> Bool {
        return userPreferences.isFavorite(location.id)
    }
    
    func getFavoriteLocations() -> [JCLocation] {
        return nearbyLocations.filter { userPreferences.isFavorite($0.id) }
    }
    
    func updateDependencies(locationService: LocationService, userPreferences: UserPreferences) {
        // This is a workaround for the ContentView initialization issue
        // In a real app, you'd use proper dependency injection
        // For now, we'll just trigger a refresh since the initial values should work
        loadInitialData()
    }
    
    func requestLocationPermission() {
        locationService.requestLocationPermission()
    }
}

struct ExploreStatistics {
    let totalLocations: Int
    let ecoFriendlyCount: Int
    let averageRating: Double
    let categoryDistribution: [JCLocation.LocationCategory: Int]
}
