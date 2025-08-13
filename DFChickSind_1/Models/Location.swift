//
//  Location.swift
//  JourneyCraft
//
//  Created by IGOR on 09/08/2025.
//

import Foundation
import CoreLocation
import MapKit

struct JCLocation: Identifiable, Codable {
    var id = UUID()
    let name: String
    let description: String
    let coordinate: CLLocationCoordinate2D
    let category: LocationCategory
    let rating: Double
    let priceLevel: PriceLevel
    let imageURL: String?
    let isEcoFriendly: Bool
    let carbonFootprint: Double? // in kg CO2
    let estimatedVisitDuration: TimeInterval // in seconds
    let openingHours: [String]
    let tags: [String]
    
    enum LocationCategory: String, CaseIterable, Codable {
        case restaurant = "Restaurant"
        case attraction = "Attraction"
        case hotel = "Hotel"
        case shopping = "Shopping"
        case nature = "Nature"
        case museum = "Museum"
        case entertainment = "Entertainment"
        case transport = "Transport"
        case wellness = "Wellness"
        case outdoor = "Outdoor"
        
        var icon: String {
            switch self {
            case .restaurant: return "fork.knife"
            case .attraction: return "star"
            case .hotel: return "bed.double"
            case .shopping: return "bag"
            case .nature: return "leaf"
            case .museum: return "building.columns"
            case .entertainment: return "theatermasks"
            case .transport: return "bus"
            case .wellness: return "heart"
            case .outdoor: return "mountain.2"
            }
        }
        
        var color: String {
            switch self {
            case .restaurant: return "#ff6b6b"
            case .attraction: return "#4ecdc4"
            case .hotel: return "#45b7d1"
            case .shopping: return "#96ceb4"
            case .nature: return "#55a3ff"
            case .museum: return "#feca57"
            case .entertainment: return "#ff9ff3"
            case .transport: return "#54a0ff"
            case .wellness: return "#5f27cd"
            case .outdoor: return "#27ae60"
            }
        }
    }
    
    enum PriceLevel: String, CaseIterable, Codable {
        case free = "Free"
        case budget = "$"
        case moderate = "$$"
        case expensive = "$$$"
        case luxury = "$$$$"
        
        var value: Int {
            switch self {
            case .free: return 0
            case .budget: return 1
            case .moderate: return 2
            case .expensive: return 3
            case .luxury: return 4
            }
        }
    }
    
    // Custom coding for CLLocationCoordinate2D
    enum CodingKeys: String, CodingKey {
        case name, description, category, rating, priceLevel, imageURL
        case isEcoFriendly, carbonFootprint, estimatedVisitDuration
        case openingHours, tags, latitude, longitude
    }
    
    init(name: String, description: String, coordinate: CLLocationCoordinate2D, 
         category: LocationCategory, rating: Double = 0.0, priceLevel: PriceLevel = .free,
         imageURL: String? = nil, isEcoFriendly: Bool = false, carbonFootprint: Double? = nil,
         estimatedVisitDuration: TimeInterval = 3600, openingHours: [String] = [], tags: [String] = []) {
        self.name = name
        self.description = description
        self.coordinate = coordinate
        self.category = category
        self.rating = rating
        self.priceLevel = priceLevel
        self.imageURL = imageURL
        self.isEcoFriendly = isEcoFriendly
        self.carbonFootprint = carbonFootprint
        self.estimatedVisitDuration = estimatedVisitDuration
        self.openingHours = openingHours
        self.tags = tags
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        category = try container.decode(LocationCategory.self, forKey: .category)
        rating = try container.decode(Double.self, forKey: .rating)
        priceLevel = try container.decode(PriceLevel.self, forKey: .priceLevel)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        isEcoFriendly = try container.decode(Bool.self, forKey: .isEcoFriendly)
        carbonFootprint = try container.decodeIfPresent(Double.self, forKey: .carbonFootprint)
        estimatedVisitDuration = try container.decode(TimeInterval.self, forKey: .estimatedVisitDuration)
        openingHours = try container.decode([String].self, forKey: .openingHours)
        tags = try container.decode([String].self, forKey: .tags)
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(category, forKey: .category)
        try container.encode(rating, forKey: .rating)
        try container.encode(priceLevel, forKey: .priceLevel)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encode(isEcoFriendly, forKey: .isEcoFriendly)
        try container.encodeIfPresent(carbonFootprint, forKey: .carbonFootprint)
        try container.encode(estimatedVisitDuration, forKey: .estimatedVisitDuration)
        try container.encode(openingHours, forKey: .openingHours)
        try container.encode(tags, forKey: .tags)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
    
    var mapItem: MKMapItem {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        return mapItem
    }
    
    func distance(from location: CLLocation) -> CLLocationDistance {
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location.distance(from: targetLocation)
    }
}
