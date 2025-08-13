//
//  NavigationService.swift
//  JourneyCraft
//
//  Created by IGOR on 09/08/2025.
//

import Foundation
import CoreLocation
import Combine

class NavigationService: ObservableObject {
    @Published var activeAlerts: [NavigationAlert] = []
    @Published var currentRoute: Route?
    @Published var estimatedArrival: Date?
    @Published var trafficConditions: TrafficCondition = .normal
    @Published var weatherConditions: WeatherCondition?
    
    private var cancellables = Set<AnyCancellable>()
    private let locationService: LocationService
    private var alertUpdateTimer: Timer?
    
    init(locationService: LocationService) {
        self.locationService = locationService
        setupAlertUpdates()
    }
    
    deinit {
        alertUpdateTimer?.invalidate()
    }
    
    // MARK: - Navigation Alerts
    struct NavigationAlert: Identifiable {
        let id = UUID()
        let type: AlertType
        let title: String
        let message: String
        let priority: Priority
        let timestamp: Date
        let actionRequired: Bool
        let suggestedAction: String?
        
        enum AlertType {
            case traffic, weather, safety, ecoTip, routeOptimization, pointOfInterest
            
            var icon: String {
                switch self {
                case .traffic: return "car.fill"
                case .weather: return "cloud.rain.fill"
                case .safety: return "exclamationmark.triangle.fill"
                case .ecoTip: return "leaf.fill"
                case .routeOptimization: return "arrow.triangle.swap"
                case .pointOfInterest: return "star.fill"
                }
            }
            
            var color: String {
                switch self {
                case .traffic: return "#ff6b6b"
                case .weather: return "#4ecdc4"
                case .safety: return "#feca57"
                case .ecoTip: return "#55a3ff"
                case .routeOptimization: return "#5f27cd"
                case .pointOfInterest: return "#3cc45b"
                }
            }
        }
        
        enum Priority: Int, CaseIterable {
            case low = 1, medium = 2, high = 3, critical = 4
            
            var description: String {
                switch self {
                case .low: return "Low"
                case .medium: return "Medium"
                case .high: return "High"
                case .critical: return "Critical"
                }
            }
        }
    }
    
    // MARK: - Route Management
    struct Route: Identifiable {
        let id = UUID()
        let origin: CLLocationCoordinate2D
        let destination: CLLocationCoordinate2D
        let waypoints: [CLLocationCoordinate2D]
        let estimatedDuration: TimeInterval
        let estimatedDistance: CLLocationDistance
        let transportationType: UserPreferences.TransportationType
        let carbonFootprint: Double
        let alternativeRoutes: [AlternativeRoute]
        
        struct AlternativeRoute {
            let name: String
            let duration: TimeInterval
            let distance: CLLocationDistance
            let carbonFootprint: Double
            let isEcoFriendly: Bool
            let waypoints: [CLLocationCoordinate2D]
        }
    }
    
    enum TrafficCondition {
        case light, normal, heavy, severe
        
        var description: String {
            switch self {
            case .light: return "Light Traffic"
            case .normal: return "Normal Traffic"
            case .heavy: return "Heavy Traffic"
            case .severe: return "Severe Traffic"
            }
        }
        
        var color: String {
            switch self {
            case .light: return "#3cc45b"
            case .normal: return "#fcc418"
            case .heavy: return "#ff6b6b"
            case .severe: return "#8b0000"
            }
        }
        
        var delayMultiplier: Double {
            switch self {
            case .light: return 0.8
            case .normal: return 1.0
            case .heavy: return 1.4
            case .severe: return 2.0
            }
        }
    }
    
    struct WeatherCondition {
        let temperature: Double
        let description: String
        let icon: String
        let precipitation: Double
        let windSpeed: Double
        let visibility: Double
        let recommendedClothing: [String]
        let travelImpact: TravelImpact
        
        enum TravelImpact {
            case none, minimal, moderate, significant
            
            var description: String {
                switch self {
                case .none: return "No travel impact"
                case .minimal: return "Minimal travel impact"
                case .moderate: return "Moderate travel impact"
                case .significant: return "Significant travel impact"
                }
            }
        }
    }
    
    // MARK: - Alert Generation
    private func setupAlertUpdates() {
        alertUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            self.updateAlerts()
        }
        
        // Listen for location updates
        locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.generateLocationBasedAlerts(for: location)
            }
            .store(in: &cancellables)
    }
    
    private func updateAlerts() {
        generateTrafficAlerts()
        generateWeatherAlerts()
        generateEcoTips()
        cleanupOldAlerts()
    }
    
    private func generateLocationBasedAlerts(for location: CLLocation) {
        generateSafetyAlerts(for: location)
        generatePointOfInterestAlerts(for: location)
    }
    
    private func generateTrafficAlerts() {
        guard let route = currentRoute else { return }
        
        // Simulate traffic condition analysis
        let trafficLevel = simulateTrafficConditions()
        trafficConditions = trafficLevel
        
        switch trafficLevel {
        case .heavy, .severe:
            let delayMinutes = Int((route.estimatedDuration * (trafficLevel.delayMultiplier - 1.0)) / 60)
            let alert = NavigationAlert(
                type: .traffic,
                title: "Heavy Traffic Detected",
                message: "Expected \(delayMinutes) minute delay on your route. Consider alternative routes or departure time.",
                priority: trafficLevel == .severe ? .high : .medium,
                timestamp: Date(),
                actionRequired: true,
                suggestedAction: "View alternative routes"
            )
            addAlert(alert)
        default:
            break
        }
    }
    
    private func generateWeatherAlerts() {
        let weather = simulateWeatherConditions()
        weatherConditions = weather
        
        if weather.travelImpact != .none {
            let alert = NavigationAlert(
                type: .weather,
                title: "Weather Advisory",
                message: "\(weather.description) - \(weather.travelImpact.description). Recommended: \(weather.recommendedClothing.joined(separator: ", "))",
                priority: weather.travelImpact == .significant ? .high : .medium,
                timestamp: Date(),
                actionRequired: weather.travelImpact == .significant,
                suggestedAction: weather.travelImpact == .significant ? "Consider indoor alternatives" : nil
            )
            addAlert(alert)
        }
    }
    
    private func generateSafetyAlerts(for location: CLLocation) {
        // Simulate safety analysis based on location
        if shouldGenerateSafetyAlert() {
            let alert = NavigationAlert(
                type: .safety,
                title: "Safety Notice",
                message: "You're entering an area with limited lighting. Stay on main paths and consider traveling in groups.",
                priority: .medium,
                timestamp: Date(),
                actionRequired: false,
                suggestedAction: "Stay alert and use well-lit paths"
            )
            addAlert(alert)
        }
    }
    
    private func generateEcoTips() {
        let tips = [
            "Consider walking to nearby destinations to reduce your carbon footprint!",
            "Public transport is available nearby - it's more eco-friendly than driving.",
            "Bike sharing stations are located within 200m of your location.",
            "This area has excellent walkability - explore on foot to discover hidden gems!",
            "Electric scooters are available for short-distance eco-friendly travel."
        ]
        
        if shouldGenerateEcoTip() {
            let tip = tips.randomElement() ?? tips[0]
            let alert = NavigationAlert(
                type: .ecoTip,
                title: "Eco-Friendly Travel Tip",
                message: tip,
                priority: .low,
                timestamp: Date(),
                actionRequired: false,
                suggestedAction: nil
            )
            addAlert(alert)
        }
    }
    
    private func generatePointOfInterestAlerts(for location: CLLocation) {
        // Simulate nearby POI discovery
        if shouldGeneratePOIAlert() {
            let alert = NavigationAlert(
                type: .pointOfInterest,
                title: "Hidden Gem Nearby",
                message: "Local favorite café 'Brew & Books' is just 100m away. Known for excellent coffee and cozy reading atmosphere.",
                priority: .low,
                timestamp: Date(),
                actionRequired: false,
                suggestedAction: "Add to itinerary"
            )
            addAlert(alert)
        }
    }
    
    private func addAlert(_ alert: NavigationAlert) {
        // Avoid duplicate alerts
        let isDuplicate = activeAlerts.contains { existingAlert in
            existingAlert.type == alert.type &&
            existingAlert.title == alert.title &&
            Date().timeIntervalSince(existingAlert.timestamp) < 300 // 5 minutes
        }
        
        if !isDuplicate {
            activeAlerts.append(alert)
            
            // Limit to 10 active alerts
            if activeAlerts.count > 10 {
                activeAlerts = Array(activeAlerts.suffix(10))
            }
        }
    }
    
    private func cleanupOldAlerts() {
        let cutoffTime = Date().addingTimeInterval(-3600) // 1 hour
        activeAlerts.removeAll { $0.timestamp < cutoffTime }
    }
    
    // MARK: - Route Planning
    func planRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, 
                   transportationType: UserPreferences.TransportationType) {
        
        // Validate coordinates
        guard origin.latitude.isFinite && origin.longitude.isFinite &&
              destination.latitude.isFinite && destination.longitude.isFinite else {
            print("⚠️ Invalid coordinates for route planning")
            return
        }
        
        let distance = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
            .distance(from: CLLocation(latitude: destination.latitude, longitude: destination.longitude))
        
        // Validate distance result
        guard distance.isFinite && distance >= 0 else {
            print("⚠️ Invalid distance calculated in route planning: \(distance)")
            return
        }
        
        let baseDuration = estimateBaseDuration(distance: distance, transport: transportationType)
        let carbonFootprint = calculateCarbonFootprint(distance: distance, transport: transportationType)
        
        // Validate calculated values
        guard baseDuration.isFinite && baseDuration > 0 &&
              carbonFootprint.isFinite && carbonFootprint >= 0 else {
            print("⚠️ Invalid calculated values: duration=\(baseDuration), carbon=\(carbonFootprint)")
            return
        }
        
        let estimatedDuration = baseDuration * trafficConditions.delayMultiplier
        guard estimatedDuration.isFinite && estimatedDuration > 0 else {
            print("⚠️ Invalid estimated duration: \(estimatedDuration)")
            return
        }
        
        let route = Route(
            origin: origin,
            destination: destination,
            waypoints: [],
            estimatedDuration: estimatedDuration,
            estimatedDistance: distance,
            transportationType: transportationType,
            carbonFootprint: carbonFootprint,
            alternativeRoutes: generateAlternativeRoutes(from: origin, to: destination, distance: distance)
        )
        
        currentRoute = route
        estimatedArrival = Date().addingTimeInterval(route.estimatedDuration)
    }
    
    private func estimateBaseDuration(distance: CLLocationDistance, transport: UserPreferences.TransportationType) -> TimeInterval {
        // Validate input distance
        guard distance.isFinite && distance >= 0 else {
            print("⚠️ Invalid distance for duration estimation: \(distance)")
            return 0.0
        }
        
        let speedKmH: Double
        switch transport {
        case .walking: speedKmH = 5
        case .cycling: speedKmH = 15
        case .publicTransport: speedKmH = 25
        case .car: speedKmH = 40
        case .mixed: speedKmH = 30
        }
        
        let distanceKm = distance / 1000.0
        guard distanceKm.isFinite else {
            print("⚠️ Invalid distance conversion: \(distanceKm)")
            return 0.0
        }
        
        let duration = (distanceKm / speedKmH) * 3600 // Convert to seconds
        return duration.isFinite ? duration : 0.0
    }
    
    private func calculateCarbonFootprint(distance: CLLocationDistance, transport: UserPreferences.TransportationType) -> Double {
        // Validate input distance
        guard distance.isFinite && distance >= 0 else {
            print("⚠️ Invalid distance for carbon footprint calculation: \(distance)")
            return 0.0
        }
        
        let emissionFactors: [UserPreferences.TransportationType: Double] = [
            .walking: 0.0,
            .cycling: 0.0,
            .publicTransport: 0.089,
            .car: 0.171,
            .mixed: 0.1
        ]
        
        let distanceKm = distance / 1000.0
        guard distanceKm.isFinite else {
            print("⚠️ Invalid distance conversion in carbon calc: \(distanceKm)")
            return 0.0
        }
        
        let emissionFactor = emissionFactors[transport] ?? 0.1
        let footprint = distanceKm * emissionFactor
        
        return footprint.isFinite ? footprint : 0.0
    }
    
    private func generateAlternativeRoutes(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, distance: CLLocationDistance) -> [Route.AlternativeRoute] {
        return [
            Route.AlternativeRoute(
                name: "Eco Route",
                duration: estimateBaseDuration(distance: distance * 1.1, transport: .publicTransport),
                distance: distance * 1.1,
                carbonFootprint: calculateCarbonFootprint(distance: distance * 1.1, transport: .publicTransport),
                isEcoFriendly: true,
                waypoints: []
            ),
            Route.AlternativeRoute(
                name: "Scenic Route",
                duration: estimateBaseDuration(distance: distance * 1.3, transport: .walking),
                distance: distance * 1.3,
                carbonFootprint: 0.0,
                isEcoFriendly: true,
                waypoints: []
            )
        ]
    }
    
    // MARK: - Alert Management
    func dismissAlert(_ alert: NavigationAlert) {
        activeAlerts.removeAll { $0.id == alert.id }
    }
    
    func dismissAllAlerts() {
        activeAlerts.removeAll()
    }
    
    func getAlerts(by priority: NavigationAlert.Priority) -> [NavigationAlert] {
        return activeAlerts.filter { $0.priority == priority }.sorted { $0.timestamp > $1.timestamp }
    }
    
    func getAlerts(by type: NavigationAlert.AlertType) -> [NavigationAlert] {
        return activeAlerts.filter { $0.type == type }.sorted { $0.timestamp > $1.timestamp }
    }
    
    // MARK: - Simulation Helpers
    private func simulateTrafficConditions() -> TrafficCondition {
        let conditions: [TrafficCondition] = [.light, .normal, .heavy, .severe]
        let weights = [0.2, 0.5, 0.25, 0.05] // Probability weights
        let random = Double.random(in: 0...1)
        
        var cumulative = 0.0
        for (index, weight) in weights.enumerated() {
            cumulative += weight
            if random <= cumulative {
                return conditions[index]
            }
        }
        return .normal
    }
    
    private func simulateWeatherConditions() -> WeatherCondition {
        let conditions = [
            WeatherCondition(
                temperature: 22,
                description: "Partly cloudy",
                icon: "cloud.sun.fill",
                precipitation: 0.1,
                windSpeed: 10,
                visibility: 10,
                recommendedClothing: ["Light jacket"],
                travelImpact: .none
            ),
            WeatherCondition(
                temperature: 15,
                description: "Light rain",
                icon: "cloud.drizzle.fill",
                precipitation: 0.8,
                windSpeed: 15,
                visibility: 8,
                recommendedClothing: ["Umbrella", "Waterproof jacket"],
                travelImpact: .minimal
            )
        ]
        
        return conditions.randomElement() ?? conditions[0]
    }
    
    private func shouldGenerateSafetyAlert() -> Bool {
        return Double.random(in: 0...1) < 0.1 // 10% chance
    }
    
    private func shouldGenerateEcoTip() -> Bool {
        return Double.random(in: 0...1) < 0.15 // 15% chance
    }
    
    private func shouldGeneratePOIAlert() -> Bool {
        return Double.random(in: 0...1) < 0.2 // 20% chance
    }
    
    // MARK: - Navigation Control
    func startNavigation(route: Route) {
        currentRoute = route
        estimatedArrival = Date().addingTimeInterval(route.estimatedDuration)
        
        // Start generating alerts
        updateAlerts()
        if let currentLocation = locationService.currentLocation {
            generateLocationBasedAlerts(for: currentLocation)
        }
        
        // Update traffic and weather
        trafficConditions = simulateTrafficConditions()
        weatherConditions = simulateWeatherConditions()
    }
    
    func stopNavigation() {
        currentRoute = nil
        estimatedArrival = nil
        activeAlerts.removeAll()
    }
    
    // MARK: - Data Management
    func clearAllData() {
        currentRoute = nil
        estimatedArrival = nil
        activeAlerts.removeAll()
        trafficConditions = .normal
        weatherConditions = nil
        alertUpdateTimer?.invalidate()
        alertUpdateTimer = nil
    }
}
