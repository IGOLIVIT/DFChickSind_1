//
//  NavigationViewModel.swift
//  JourneyCraft
//
//  Created by IGOR on 09/08/2025.
//

import Foundation
import Combine
import CoreLocation
import MapKit

class NavigationViewModel: ObservableObject {
    @Published var activeAlerts: [NavigationService.NavigationAlert] = []
    @Published var currentRoute: NavigationService.Route?
    @Published var estimatedArrival: Date?
    @Published var trafficConditions: NavigationService.TrafficCondition = .normal
    @Published var weatherConditions: NavigationService.WeatherCondition?
    @Published var isNavigating = false
    @Published var showingAlertDetail = false
    @Published var selectedAlert: NavigationService.NavigationAlert?
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    private let navigationService: NavigationService
    private let locationService: LocationService
    private var cancellables = Set<AnyCancellable>()
    
    init(navigationService: NavigationService, locationService: LocationService) {
        self.navigationService = navigationService
        self.locationService = locationService
        
        setupBindings()
    }
    
    private func setupBindings() {
        navigationService.$activeAlerts
            .assign(to: \.activeAlerts, on: self)
            .store(in: &cancellables)
        
        navigationService.$currentRoute
            .assign(to: \.currentRoute, on: self)
            .store(in: &cancellables)
        
        navigationService.$estimatedArrival
            .assign(to: \.estimatedArrival, on: self)
            .store(in: &cancellables)
        
        navigationService.$trafficConditions
            .assign(to: \.trafficConditions, on: self)
            .store(in: &cancellables)
        
        navigationService.$weatherConditions
            .assign(to: \.weatherConditions, on: self)
            .store(in: &cancellables)
        
        locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.updateMapRegion(for: location.coordinate)
            }
            .store(in: &cancellables)
    }
    
    private func updateMapRegion(for coordinate: CLLocationCoordinate2D) {
        // Validate coordinate before using
        guard coordinate.latitude.isFinite && coordinate.longitude.isFinite &&
              coordinate.latitude >= -90 && coordinate.latitude <= 90 &&
              coordinate.longitude >= -180 && coordinate.longitude <= 180 else {
            print("⚠️ Invalid coordinate in updateMapRegion: lat=\(coordinate.latitude), lon=\(coordinate.longitude)")
            return
        }
        
        mapRegion = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    // MARK: - Navigation Actions
    func startNavigation(to destination: CLLocationCoordinate2D, transportationType: UserPreferences.TransportationType) {
        guard let currentLocation = locationService.currentLocation else { 
            print("⚠️ No current location available for navigation")
            return 
        }
        
        // Validate current location coordinate
        let currentCoord = currentLocation.coordinate
        guard currentCoord.latitude.isFinite && currentCoord.longitude.isFinite &&
              currentCoord.latitude >= -90 && currentCoord.latitude <= 90 &&
              currentCoord.longitude >= -180 && currentCoord.longitude <= 180 else {
            print("⚠️ Invalid current location coordinate: lat=\(currentCoord.latitude), lon=\(currentCoord.longitude)")
            return
        }
        
        // Validate destination coordinate
        guard destination.latitude.isFinite && destination.longitude.isFinite &&
              destination.latitude >= -90 && destination.latitude <= 90 &&
              destination.longitude >= -180 && destination.longitude <= 180 else {
            print("⚠️ Invalid destination coordinate: lat=\(destination.latitude), lon=\(destination.longitude)")
            return
        }
        
        navigationService.planRoute(
            from: currentCoord,
            to: destination,
            transportationType: transportationType
        )
        
        isNavigating = true
    }
    
    func stopNavigation() {
        isNavigating = false
        currentRoute = nil
        estimatedArrival = nil
    }
    
    func navigateToItinerary(_ itinerary: Itinerary, transportationType: UserPreferences.TransportationType) {
        guard let firstDestination = itinerary.destinations.first else { return }
        startNavigation(to: firstDestination.coordinate, transportationType: transportationType)
    }
    
    // MARK: - Alert Management
    func dismissAlert(_ alert: NavigationService.NavigationAlert) {
        navigationService.dismissAlert(alert)
    }
    
    func dismissAllAlerts() {
        navigationService.dismissAllAlerts()
    }
    
    func selectAlert(_ alert: NavigationService.NavigationAlert) {
        selectedAlert = alert
        showingAlertDetail = true
    }
    
    func getHighPriorityAlerts() -> [NavigationService.NavigationAlert] {
        return navigationService.getAlerts(by: .high) + navigationService.getAlerts(by: .critical)
    }
    
    func getAlertsByType(_ type: NavigationService.NavigationAlert.AlertType) -> [NavigationService.NavigationAlert] {
        return navigationService.getAlerts(by: type)
    }
    
    // MARK: - Route Information
    func getFormattedETA() -> String {
        guard let eta = estimatedArrival else { return "Not available" }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: eta)
    }
    
    func getFormattedDuration() -> String {
        guard let route = currentRoute else { return "Not available" }
        
        let hours = Int(route.estimatedDuration) / 3600
        let minutes = Int(route.estimatedDuration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    func getFormattedDistance() -> String {
        guard let route = currentRoute else { return "Not available" }
        
        let distance = route.estimatedDistance / 1000.0 // Convert to km
        return String(format: "%.1f km", distance)
    }
    
    func getFormattedCarbonFootprint() -> String {
        guard let route = currentRoute else { return "Not available" }
        return String(format: "%.1f kg CO₂", route.carbonFootprint)
    }
    
    // MARK: - Weather Information
    func getWeatherDescription() -> String {
        guard let weather = weatherConditions else { return "Weather data unavailable" }
        return "\(Int(weather.temperature))°C, \(weather.description)"
    }
    
    func getWeatherIcon() -> String {
        return weatherConditions?.icon ?? "questionmark"
    }
    
    func shouldShowWeatherAlert() -> Bool {
        guard let weather = weatherConditions else { return false }
        return weather.travelImpact != .none
    }
    
    // MARK: - Traffic Information
    func getTrafficDescription() -> String {
        return trafficConditions.description
    }
    
    func getTrafficColor() -> String {
        return trafficConditions.color
    }
    
    func shouldShowTrafficAlert() -> Bool {
        return trafficConditions == .heavy || trafficConditions == .severe
    }
    
    // MARK: - Alternative Routes
    func getAlternativeRoutes() -> [NavigationService.Route.AlternativeRoute] {
        return currentRoute?.alternativeRoutes ?? []
    }
    
    func selectAlternativeRoute(_ alternative: NavigationService.Route.AlternativeRoute) {
        // Update the current route with the selected alternative
        // This would typically recalculate the route and update navigation
        currentRoute = NavigationService.Route(
            origin: currentRoute?.origin ?? CLLocationCoordinate2D(),
            destination: currentRoute?.destination ?? CLLocationCoordinate2D(),
            waypoints: alternative.waypoints,
            estimatedDuration: alternative.duration,
            estimatedDistance: alternative.distance,
            transportationType: currentRoute?.transportationType ?? .mixed,
            carbonFootprint: alternative.carbonFootprint,
            alternativeRoutes: []
        )
    }
    
    func getEcoFriendlyRoutes() -> [NavigationService.Route.AlternativeRoute] {
        return getAlternativeRoutes().filter { $0.isEcoFriendly }
    }
    
    // MARK: - Alert Statistics
    func getAlertCounts() -> (total: Int, high: Int, eco: Int) {
        let high = activeAlerts.filter { $0.priority == .high || $0.priority == .critical }.count
        let eco = activeAlerts.filter { $0.type == .ecoTip }.count
        return (activeAlerts.count, high, eco)
    }
    
    func getRecentAlerts(limit: Int = 5) -> [NavigationService.NavigationAlert] {
        return activeAlerts
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Map Helpers
    func centerMapOnCurrentLocation() {
        guard let currentLocation = locationService.currentLocation else { return }
        updateMapRegion(for: currentLocation.coordinate)
    }
    
    func centerMapOnRoute() {
        guard let route = currentRoute else { return }
        
        let coordinates = [route.origin, route.destination] + route.waypoints
        let region = getRegionForCoordinates(coordinates)
        mapRegion = region
    }
    
    private func getRegionForCoordinates(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else { return mapRegion }
        
        // Safe calculations with validation
        guard let minLat = coordinates.map({ $0.latitude }).min(),
              let maxLat = coordinates.map({ $0.latitude }).max(),
              let minLon = coordinates.map({ $0.longitude }).min(),
              let maxLon = coordinates.map({ $0.longitude }).max(),
              minLat.isFinite, maxLat.isFinite, minLon.isFinite, maxLon.isFinite else {
            return mapRegion
        }
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        // Validate center coordinates
        guard centerLat.isFinite && centerLon.isFinite else {
            return mapRegion
        }
        
        let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
        
        let latDelta = max(0.01, (maxLat - minLat) * 1.3)
        let lonDelta = max(0.01, (maxLon - minLon) * 1.3)
        
        // Validate span values
        guard latDelta.isFinite && lonDelta.isFinite && latDelta > 0 && lonDelta > 0 else {
            return MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        return MKCoordinateRegion(center: center, span: span)
    }
    
    // MARK: - Helper Methods
    func formatAlertTime(_ timestamp: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(timestamp)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: timestamp)
        }
    }
    
    func getPriorityDisplayText(_ priority: NavigationService.NavigationAlert.Priority) -> String {
        return priority.description.uppercased()
    }
    
    func shouldAutoShowAlert(_ alert: NavigationService.NavigationAlert) -> Bool {
        return alert.priority == .critical || (alert.priority == .high && alert.actionRequired)
    }
    
    func getNavigationStatus() -> String {
        if isNavigating {
            if let eta = estimatedArrival {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "Arriving at \(formatter.string(from: eta))"
            } else {
                return "Navigating..."
            }
        } else {
            return "Ready to navigate"
        }
    }
    
    // MARK: - Extended Navigation Functions
    func startNavigation(for itinerary: Itinerary) {
        guard !itinerary.destinations.isEmpty else { return }
        
        isNavigating = true
        
        // Create a simple route from destinations
        let startLocation = itinerary.destinations.first!
        let endLocation = itinerary.destinations.last!
        let waypoints = Array(itinerary.destinations.dropFirst().dropLast())
        
        // Simple distance calculation (sum of distances between consecutive points)
        var totalDistance: CLLocationDistance = 0
        for i in 0..<(itinerary.destinations.count - 1) {
            let location1 = CLLocation(latitude: itinerary.destinations[i].coordinate.latitude, 
                                     longitude: itinerary.destinations[i].coordinate.longitude)
            let location2 = CLLocation(latitude: itinerary.destinations[i+1].coordinate.latitude, 
                                     longitude: itinerary.destinations[i+1].coordinate.longitude)
            totalDistance += location1.distance(from: location2)
        }
        
        // Calculate carbon footprint based on transport type
        let carbonPerKm: Double = {
            switch itinerary.preferredTransportation {
            case .walking: return 0.0
            case .cycling: return 0.0
            case .publicTransport: return 0.04
            case .car: return 0.12
            case .mixed: return 0.08
            }
        }()
        
        let route = NavigationService.Route(
            origin: startLocation.coordinate,
            destination: endLocation.coordinate,
            waypoints: waypoints.map { $0.coordinate },
            estimatedDuration: totalDistance / 15.0 * 60, // 15 km/h average speed
            estimatedDistance: totalDistance,
            transportationType: itinerary.preferredTransportation,
            carbonFootprint: (totalDistance / 1000.0) * carbonPerKm,
            alternativeRoutes: []
        )
        
        currentRoute = route
        estimatedArrival = Date().addingTimeInterval(route.estimatedDuration)
        
        // Center map on the route
        centerMapOnItinerary(itinerary)
        
        navigationService.startNavigation(route: route)
    }
    
    func setCurrentDestination(_ destination: JCLocation) {
        // Validate coordinates before setting
        let coord = destination.coordinate
        guard coord.latitude.isFinite && coord.longitude.isFinite &&
              coord.latitude >= -90 && coord.latitude <= 90 &&
              coord.longitude >= -180 && coord.longitude <= 180 else {
            print("⚠️ Invalid destination coordinate: lat=\(coord.latitude), lon=\(coord.longitude)")
            return
        }
        
        mapRegion.center = coord
        mapRegion.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    }
    
    func centerMapOnItinerary(_ itinerary: Itinerary) {
        let coordinates = itinerary.destinations.map { $0.coordinate }
        let region = getRegionForCoordinates(coordinates)
        mapRegion = region
    }
}
