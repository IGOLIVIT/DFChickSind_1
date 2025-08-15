//
//  ItineraryViewModel.swift
//  JourneyCraft
//
//  Created by IGOR on 09/08/2025.
//

import Foundation
import Combine
import CoreLocation

class ItineraryViewModel: ObservableObject {
    @Published var itineraries: [Itinerary] = []
    @Published var currentItinerary: Itinerary?
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var selectedFilter: FilterOption = .all
    @Published var showingCreateItinerary = false
    @Published var showingItineraryDetail = false
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case adventure = "Adventure"
        case relaxation = "Relaxation"
        case cultural = "Cultural"
        case balanced = "Balanced"
        case ecoFriendly = "Eco-Friendly"
        
        var travelStyle: UserPreferences.TravelStyle? {
            switch self {
            case .adventure: return .adventure
            case .relaxation: return .relaxation
            case .cultural: return .cultural
            case .balanced: return .balanced
            default: return nil
            }
        }
    }
    
    private let itineraryService: ItineraryService
    private let locationService: LocationService
    private var cancellables = Set<AnyCancellable>()
    
    init(itineraryService: ItineraryService, locationService: LocationService) {
        self.itineraryService = itineraryService
        self.locationService = locationService
        
        setupBindings()
        loadItineraries()
    }
    
    private func setupBindings() {
        itineraryService.$itineraries
            .sink { [weak self] newItineraries in
                self?.itineraries = newItineraries
            }
            .store(in: &cancellables)
        
        itineraryService.$currentItinerary
            .assign(to: \.currentItinerary, on: self)
            .store(in: &cancellables)
    }
    
    var filteredItineraries: [Itinerary] {
        var filtered = itineraries
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = itineraryService.searchItineraries(searchText)
        }
        
        // Apply category filter
        switch selectedFilter {
        case .all:
            break
        case .ecoFriendly:
            filtered = filtered.filter { $0.isEcoFriendly }
        case .adventure, .relaxation, .cultural, .balanced:
            if let style = selectedFilter.travelStyle {
                filtered = filtered.filter { $0.travelStyle == style }
            }
        }
        
        return filtered.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    // MARK: - Actions
    func loadItineraries() {
        // Trigger manual refresh if needed
        // Since we use binding, this ensures data is synchronized
        objectWillChange.send()
    }
    
    func updateItinerary(_ itinerary: Itinerary) {
        // Update in local array
        if let index = itineraries.firstIndex(where: { $0.id == itinerary.id }) {
            itineraries[index] = itinerary
        }
        
        // Update current itinerary if it's the same one
        if currentItinerary?.id == itinerary.id {
            currentItinerary = itinerary
        }
        
        // Update in the service
        itineraryService.updateItinerary(itinerary)
    }
    
    func deleteItinerary(_ itinerary: Itinerary) {
        itineraryService.deleteItinerary(itinerary)
    }
    
    func duplicateItinerary(_ itinerary: Itinerary) {
        itineraryService.duplicateItinerary(itinerary)
    }
    
    func generateSmartItinerary(
        title: String,
        startDate: Date,
        endDate: Date,
        preferences: UserPreferences
    ) {
        print("🤖 ItineraryViewModel.generateSmartItinerary called for: '\(title)'")
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                print("❌ Self is nil in generateSmartItinerary")
                return
            }
            
            guard let currentLocation = self.locationService.currentLocation else {
                print("❌ No current location available for smart generation")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            print("🌍 Current location: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)")
            
            let itinerary = self.itineraryService.generateSmartItinerary(
                title: title,
                startDate: startDate,
                endDate: endDate,
                startLocation: currentLocation.coordinate,
                preferences: preferences,
                locationService: self.locationService
            )
            
            print("✅ Smart itinerary generated: '\(itinerary.title)' with \(itinerary.destinations.count) destinations")
            
            DispatchQueue.main.async {
                print("📱 Adding smart itinerary to service...")
                self.itineraryService.addItinerary(itinerary)
                self.currentItinerary = itinerary
                self.isLoading = false
                self.showingItineraryDetail = true
                print("✅ Smart itinerary added and UI updated!")
            }
        }
    }
    
    func optimizeItinerary(_ itinerary: Itinerary) {
        // For now, just update the itinerary as-is
        // In a real implementation, this would reorder destinations for optimal routing
        self.updateItinerary(itinerary)
    }
    
    func selectItinerary(_ itinerary: Itinerary) {
        currentItinerary = itinerary
        itineraryService.currentItinerary = itinerary
        showingItineraryDetail = true
    }
    
    func addDestinationToCurrentItinerary(_ location: JCLocation) {
        guard var itinerary = currentItinerary else { return }
        itinerary.addDestination(location)
        self.updateItinerary(itinerary)
    }
    
    func removeDestinationFromCurrentItinerary(at index: Int) {
        guard var itinerary = currentItinerary else { return }
        itinerary.removeDestination(at: index)
        self.updateItinerary(itinerary)
    }
    
    func reorderDestinationsInCurrentItinerary(from source: IndexSet, to destination: Int) {
        guard var itinerary = currentItinerary else { return }
        itinerary.reorderDestinations(from: source, to: destination)
        self.updateItinerary(itinerary)
    }
    
    func createCustomDestination(name: String, description: String, category: JCLocation.LocationCategory = .attraction) -> JCLocation {
        return JCLocation(
            name: name,
            description: description,
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), // Default coordinates
            category: category,
            rating: 0.0,
            priceLevel: .free,
            isEcoFriendly: true,
            carbonFootprint: 0.0,
            estimatedVisitDuration: 60,
            openingHours: [],
            tags: ["custom"]
        )
    }
    
    // MARK: - Popular Destinations
    func getPopularDestinations() -> [JCLocation] {
        // Return popular destinations for quick adding
        return [
            JCLocation(
                name: "Golden Gate Bridge",
                description: "Iconic suspension bridge in San Francisco",
                coordinate: CLLocationCoordinate2D(latitude: 37.8199, longitude: -122.4783),
                category: .attraction
            ),
            JCLocation(
                name: "Central Park",
                description: "Large public park in Manhattan, New York City",
                coordinate: CLLocationCoordinate2D(latitude: 40.7829, longitude: -73.9654),
                category: .nature
            ),
            JCLocation(
                name: "Louvre Museum",
                description: "World's largest art museum in Paris",
                coordinate: CLLocationCoordinate2D(latitude: 48.8606, longitude: 2.3376),
                category: .museum
            )
        ]
    }
    
    // MARK: - Helper Methods
    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    func formatDistance(_ distance: Double) -> String {
        if distance < 1 {
            return "\(Int(distance * 1000))m"
        } else {
            return String(format: "%.1f km", distance)
        }
    }
    
    func formatCarbonFootprint(_ footprint: Double) -> String {
        return String(format: "%.1f kg CO₂", footprint)
    }
    
    func formatCost(_ cost: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: cost)) ?? "$\(Int(cost))"
    }
    
    func getEcoRatingDescription(_ rating: Int) -> String {
        switch rating {
        case 5: return "Excellent"
        case 4: return "Very Good"
        case 3: return "Good"
        case 2: return "Fair"
        case 1: return "Poor"
        default: return "Not Rated"
        }
    }
    
    func getItineraryStatusDescription(_ itinerary: Itinerary) -> String {
        let now = Date()
        
        if now < itinerary.startDate {
            let days = Calendar.current.dateComponents([.day], from: now, to: itinerary.startDate).day ?? 0
            if days == 0 {
                return "Starting today"
            } else if days == 1 {
                return "Starting tomorrow"
            } else {
                return "Starting in \(days) days"
            }
        } else if now >= itinerary.startDate && now <= itinerary.endDate {
            return "In progress"
        } else {
            return "Completed"
        }
    }
    
    func getRecommendedItineraries(for preferences: UserPreferences) -> [Itinerary] {
        return itineraries
            .filter { $0.travelStyle == preferences.travelStyle }
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(3)
            .map { $0 }
    }
    
    func getStatistics() -> ItineraryStatistics {
        let totalTrips = itineraries.count
        let totalDestinations = itineraries.reduce(0) { $0 + $1.destinations.count }
        let totalDistance = itineraries.reduce(0.0) { $0 + $1.totalDistance }
        let ecoFriendlyTrips = itineraries.filter { $0.isEcoFriendly }.count
        let totalCarbonSaved = itineraries.filter { $0.isEcoFriendly }.reduce(0.0) { $0 + (50.0 - $1.estimatedCarbonFootprint) }
        let averageRating = calculateAverageRating()
        
        return ItineraryStatistics(
            totalTrips: totalTrips,
            totalDestinations: totalDestinations,
            totalDistance: totalDistance,
            ecoFriendlyTrips: ecoFriendlyTrips,
            carbonFootprintSaved: max(0, totalCarbonSaved),
            averageRating: averageRating
        )
    }
    
    private func calculateAverageRating() -> Double {
        let allDestinations = itineraries.flatMap { $0.destinations }
        guard !allDestinations.isEmpty else { return 0.0 }
        
        let totalRating = allDestinations.reduce(0.0) { $0 + $1.rating }
        return totalRating / Double(allDestinations.count)
    }
    
    // MARK: - Itinerary Creation
    func createItinerary(_ itinerary: Itinerary) {
        print("🚀 ItineraryViewModel.createItinerary called for: '\(itinerary.title)'")
        itineraryService.addItinerary(itinerary)
        loadItineraries()
        print("📱 UI refresh triggered")
    }
    
    // MARK: - Data Management
    func clearAllData() {
        itineraryService.clearAllData()
        loadItineraries() // Refresh the UI
    }
}

struct ItineraryStatistics {
    let totalTrips: Int
    let totalDestinations: Int
    let totalDistance: Double
    let ecoFriendlyTrips: Int
    let carbonFootprintSaved: Double
    let averageRating: Double
}
