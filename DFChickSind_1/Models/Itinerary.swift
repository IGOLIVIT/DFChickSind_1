//
//  Itinerary.swift
//  JourneyCraft
//
//  Created by IGOR on 09/08/2025.
//

import Foundation
import CoreLocation

struct Itinerary: Identifiable, Codable {
    var id = UUID()
    var title: String
    var description: String
    var destinations: [JCLocation]
    var startDate: Date
    var endDate: Date
    var totalDistance: Double // in kilometers
    var estimatedCarbonFootprint: Double // in kg CO2
    var estimatedCost: Double
    var travelStyle: UserPreferences.TravelStyle
    var preferredTransportation: UserPreferences.TransportationType
    var tags: [String]
    var isEcoFriendly: Bool
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, destinations, startDate, endDate
        case totalDistance, estimatedCarbonFootprint, estimatedCost
        case travelStyle, preferredTransportation, tags, isEcoFriendly, notes, createdAt, updatedAt
    }
    
    init(title: String, description: String = "", destinations: [JCLocation] = [], 
         startDate: Date = Date(), endDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
         travelStyle: UserPreferences.TravelStyle = .balanced, preferredTransportation: UserPreferences.TransportationType = .mixed, 
         tags: [String] = [], notes: String = "") {
        self.title = title
        self.description = description
        self.destinations = destinations
        self.startDate = startDate
        self.endDate = endDate
        self.travelStyle = travelStyle
        self.preferredTransportation = preferredTransportation
        self.tags = tags
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
        
        // Calculate derived properties
        self.totalDistance = Self.calculateTotalDistance(destinations: destinations)
        self.estimatedCarbonFootprint = Self.calculateCarbonFootprint(destinations: destinations, distance: self.totalDistance)
        self.estimatedCost = Self.calculateEstimatedCost(destinations: destinations)
        self.isEcoFriendly = self.estimatedCarbonFootprint <= 50.0 // Threshold for eco-friendly trips
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        destinations = try container.decode([JCLocation].self, forKey: .destinations)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        totalDistance = try container.decode(Double.self, forKey: .totalDistance)
        estimatedCarbonFootprint = try container.decode(Double.self, forKey: .estimatedCarbonFootprint)
        estimatedCost = try container.decode(Double.self, forKey: .estimatedCost)
        travelStyle = try container.decode(UserPreferences.TravelStyle.self, forKey: .travelStyle)
        preferredTransportation = try container.decode(UserPreferences.TransportationType.self, forKey: .preferredTransportation)
        tags = try container.decode([String].self, forKey: .tags)
        isEcoFriendly = try container.decode(Bool.self, forKey: .isEcoFriendly)
        notes = try container.decode(String.self, forKey: .notes)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(destinations, forKey: .destinations)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(totalDistance, forKey: .totalDistance)
        try container.encode(estimatedCarbonFootprint, forKey: .estimatedCarbonFootprint)
        try container.encode(estimatedCost, forKey: .estimatedCost)
        try container.encode(travelStyle, forKey: .travelStyle)
        try container.encode(preferredTransportation, forKey: .preferredTransportation)
        try container.encode(tags, forKey: .tags)
        try container.encode(isEcoFriendly, forKey: .isEcoFriendly)
        try container.encode(notes, forKey: .notes)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    mutating func addDestination(_ location: JCLocation) {
        destinations.append(location)
        updateCalculatedProperties()
    }
    
    mutating func removeDestination(at index: Int) {
        guard index < destinations.count else { return }
        destinations.remove(at: index)
        updateCalculatedProperties()
    }
    
    mutating func reorderDestinations(from source: IndexSet, to destination: Int) {
        destinations.move(fromOffsets: source, toOffset: destination)
        updateCalculatedProperties()
    }
    
    mutating func updateCalculatedProperties() {
        totalDistance = Self.calculateTotalDistance(destinations: destinations)
        estimatedCarbonFootprint = Self.calculateCarbonFootprint(destinations: destinations, distance: totalDistance)
        estimatedCost = Self.calculateEstimatedCost(destinations: destinations)
        isEcoFriendly = estimatedCarbonFootprint <= 50.0
        updatedAt = Date()
    }
    
    static func calculateTotalDistance(destinations: [JCLocation]) -> Double {
        guard destinations.count > 1 else { return 0.0 }
        
        var totalDistance: Double = 0.0
        for i in 0..<(destinations.count - 1) {
            let startCoord = destinations[i].coordinate
            let endCoord = destinations[i + 1].coordinate
            
            // Validate coordinates before calculation
            guard startCoord.latitude.isFinite && startCoord.longitude.isFinite &&
                  endCoord.latitude.isFinite && endCoord.longitude.isFinite else {
                print("⚠️ Invalid coordinates detected in distance calculation")
                continue
            }
            
            let start = CLLocation(latitude: startCoord.latitude, longitude: startCoord.longitude)
            let end = CLLocation(latitude: endCoord.latitude, longitude: endCoord.longitude)
            
            let distance = start.distance(from: end)
            
            // Validate distance result
            guard distance.isFinite && distance >= 0 else {
                print("⚠️ Invalid distance calculated: \(distance)")
                continue
            }
            
            totalDistance += distance / 1000.0 // Convert to kilometers
        }
        
        return totalDistance.isFinite ? totalDistance : 0.0
    }
    
    static func calculateCarbonFootprint(destinations: [JCLocation], distance: Double) -> Double {
        // Validate input distance
        guard distance.isFinite && distance >= 0 else {
            print("⚠️ Invalid distance for carbon footprint calculation: \(distance)")
            return 0.0
        }
        
        let transportEmissionFactor = 0.21 // kg CO2 per km (average for mixed transport)
        let transportFootprint = distance * transportEmissionFactor
        
        // Validate transport footprint
        guard transportFootprint.isFinite else {
            print("⚠️ Invalid transport footprint calculated")
            return 0.0
        }
        
        let locationFootprints = destinations.compactMap { $0.carbonFootprint }.reduce(0, +)
        
        // Validate location footprints
        guard locationFootprints.isFinite else {
            print("⚠️ Invalid location footprints calculated")
            return transportFootprint
        }
        
        let totalFootprint = transportFootprint + locationFootprints
        return totalFootprint.isFinite ? totalFootprint : 0.0
    }
    
    static func calculateEstimatedCost(destinations: [JCLocation]) -> Double {
        let baseCosts: [JCLocation.PriceLevel: Double] = [
            .free: 0,
            .budget: 15,
            .moderate: 35,
            .expensive: 75,
            .luxury: 150
        ]
        
        return destinations.reduce(0) { total, location in
            total + (baseCosts[location.priceLevel] ?? 0)
        }
    }
    
    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
    
    var formattedDuration: String {
        let days = Int(duration / 86400) // 86400 seconds in a day
        if days == 0 {
            return "Same day"
        } else if days == 1 {
            return "1 day"
        } else {
            return "\(days) days"
        }
    }
    
    var ecoFriendlyScore: Int {
        let maxFootprint = 100.0 // Maximum expected footprint
        let score = max(0, Int((1.0 - (estimatedCarbonFootprint / maxFootprint)) * 5))
        return min(5, score) // Cap at 5 stars
    }
}
