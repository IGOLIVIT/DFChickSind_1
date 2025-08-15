//
//  LocationService.swift
//  JourneyCraft
//
//  Created by IGOR on 09/08/2025.
//

import Foundation
import CoreLocation
import Combine
import UIKit

class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationPermissionDenied: Bool = false
    @Published var isLocationEnabled: Bool = false
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0 // Update every 10 meters
        authorizationStatus = locationManager.authorizationStatus
        updateLocationEnabled()
    }
    
    func requestLocationPermission() {
        print("🔍 LocationService: requestLocationPermission called with status: \(authorizationStatus.rawValue)")
        
        // Ensure we have fresh status
        let currentStatus = locationManager.authorizationStatus
        authorizationStatus = currentStatus
        print("🔄 Updated status check: \(currentStatus.rawValue)")
        
        switch currentStatus {
        case .notDetermined:
            print("📍 LocationService: Requesting authorization...")
            DispatchQueue.main.async {
                self.locationManager.requestWhenInUseAuthorization()
                print("📱 Authorization request sent on main queue")
            }
        case .denied, .restricted:
            print("❌ LocationService: Permission denied/restricted, opening settings...")
            locationPermissionDenied = true
            openLocationSettings()
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ LocationService: Already authorized, starting updates...")
            startLocationUpdates()
        @unknown default:
            print("⚠️ LocationService: Unknown authorization status")
            break
        }
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        
        guard CLLocationManager.locationServicesEnabled() else {
            return
        }
        
        locationManager.startUpdatingLocation()
        isLocationEnabled = true
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLocationEnabled = false
    }
    
    private func updateLocationEnabled() {
        isLocationEnabled = (authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways) && CLLocationManager.locationServicesEnabled()
    }
    
    func openLocationSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            DispatchQueue.main.async {
                UIApplication.shared.open(settingsUrl)
            }
        }
    }
    
    // MARK: - Location Search
    func searchNearbyLocations(category: JCLocation.LocationCategory? = nil, radius: CLLocationDistance = 5000) -> [JCLocation] {
        // Mock data for demonstration - in a real app, this would integrate with APIs like Google Places, Foursquare, etc.
        guard let currentLocation = currentLocation else { return [] }
        
        return MockLocationData.generateNearbyLocations(around: currentLocation.coordinate, category: category, radius: radius)
    }
    
    func searchLocations(query: String, near coordinate: CLLocationCoordinate2D? = nil) -> [JCLocation] {
        let searchCoordinate = coordinate ?? currentLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        return MockLocationData.searchLocations(query: query, near: searchCoordinate)
    }
    
    func getEcoFriendlyAlternatives(for location: JCLocation) -> [JCLocation] {
        return MockLocationData.getEcoFriendlyAlternatives(for: location)
    }
    
    // MARK: - Data Management
    func clearAllData() {
        stopLocationUpdates()
        currentLocation = nil
        authorizationStatus = .notDetermined
        locationPermissionDenied = false
        isLocationEnabled = false
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("🔄 LocationService: Authorization changed to: \(status.rawValue)")
        authorizationStatus = status
        updateLocationEnabled()
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ LocationService: Permission granted!")
            locationPermissionDenied = false
            startLocationUpdates()
        case .denied, .restricted:
            print("❌ LocationService: Permission denied in delegate!")
            locationPermissionDenied = true
            stopLocationUpdates()
        case .notDetermined:
            print("❓ LocationService: Permission not determined")
            locationPermissionDenied = false
        @unknown default:
            print("⚠️ LocationService: Unknown status in delegate")
            break
        }
    }
}

// MARK: - Mock Data Helper
struct MockLocationData {
    static func generateNearbyLocations(around coordinate: CLLocationCoordinate2D, category: JCLocation.LocationCategory?, radius: CLLocationDistance) -> [JCLocation] {
        let baseLocations = [
            JCLocation(
                name: "Central Park",
                description: "Beautiful urban park perfect for morning jogs and picnics",
                coordinate: CLLocationCoordinate2D(latitude: coordinate.latitude + 0.01, longitude: coordinate.longitude + 0.01),
                category: .nature,
                rating: 4.7,
                priceLevel: .free,
                isEcoFriendly: true,
                carbonFootprint: 0.0,
                estimatedVisitDuration: 7200,
                openingHours: ["6:00 AM - 1:00 AM"],
                tags: ["outdoor", "peaceful", "jogging"]
            ),
            JCLocation(
                name: "Local Art Museum",
                description: "Contemporary art exhibitions featuring local and international artists",
                coordinate: CLLocationCoordinate2D(latitude: coordinate.latitude - 0.005, longitude: coordinate.longitude + 0.015),
                category: .museum,
                rating: 4.3,
                priceLevel: .moderate,
                isEcoFriendly: true,
                carbonFootprint: 2.1,
                estimatedVisitDuration: 5400,
                openingHours: ["10:00 AM - 6:00 PM"],
                tags: ["culture", "art", "educational"]
            ),
            JCLocation(
                name: "Organic Café",
                description: "Farm-to-table café serving locally sourced organic meals",
                coordinate: CLLocationCoordinate2D(latitude: coordinate.latitude + 0.008, longitude: coordinate.longitude - 0.012),
                category: .restaurant,
                rating: 4.5,
                priceLevel: .moderate,
                isEcoFriendly: true,
                carbonFootprint: 1.2,
                estimatedVisitDuration: 3600,
                openingHours: ["7:00 AM - 3:00 PM"],
                tags: ["organic", "healthy", "local"]
            ),
            JCLocation(
                name: "Vintage Market",
                description: "Unique vintage clothing and handmade crafts from local artisans",
                coordinate: CLLocationCoordinate2D(latitude: coordinate.latitude - 0.003, longitude: coordinate.longitude - 0.008),
                category: .shopping,
                rating: 4.2,
                priceLevel: .budget,
                isEcoFriendly: true,
                carbonFootprint: 0.5,
                estimatedVisitDuration: 4800,
                openingHours: ["11:00 AM - 7:00 PM"],
                tags: ["vintage", "handmade", "unique"]
            ),
            JCLocation(
                name: "Wellness Spa",
                description: "Holistic wellness center offering massages and meditation sessions",
                coordinate: CLLocationCoordinate2D(latitude: coordinate.latitude + 0.015, longitude: coordinate.longitude + 0.005),
                category: .wellness,
                rating: 4.8,
                priceLevel: .expensive,
                isEcoFriendly: true,
                carbonFootprint: 1.8,
                estimatedVisitDuration: 5400,
                openingHours: ["9:00 AM - 8:00 PM"],
                tags: ["relaxation", "wellness", "spa"]
            )
        ]
        
        if let category = category {
            return baseLocations.filter { $0.category == category }
        }
        
        return baseLocations
    }
    
    static func searchLocations(query: String, near coordinate: CLLocationCoordinate2D) -> [JCLocation] {
        let allLocations = generateNearbyLocations(around: coordinate, category: nil, radius: 10000)
        return allLocations.filter { location in
            location.name.localizedCaseInsensitiveContains(query) ||
            location.description.localizedCaseInsensitiveContains(query) ||
            location.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    static func getEcoFriendlyAlternatives(for location: JCLocation) -> [JCLocation] {
        let alternatives = generateNearbyLocations(around: location.coordinate, category: location.category, radius: 2000)
        return alternatives.filter { $0.isEcoFriendly && $0.id != location.id }
    }
}
