//
//  ExploreDetailView.swift
//  JourneyCraft
//
//  Created by IGOR on 09/08/2025.
//

import SwiftUI
import MapKit

struct ExploreDetailView: View {
    let location: JCLocation
    @EnvironmentObject private var exploreViewModel: ExploreViewModel
    @EnvironmentObject private var itineraryViewModel: ItineraryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingMap = false
    @State private var ecoAlternatives: [JCLocation] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(hex: "#3e4464"),
                        Color(hex: "#3e4464").opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header section
                        headerSection
                        
                        // Location info
                        locationInfoSection
                        
                        // Description
                        descriptionSection
                        
                        // Details and amenities
                        detailsSection
                        
                        // Eco information
                        if location.isEcoFriendly {
                            ecoSection
                        }
                        
                        // Eco alternatives
                        if !ecoAlternatives.isEmpty {
                            ecoAlternativesSection
                        }
                        
                        // Action buttons
                        actionButtonsSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle(location.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            exploreViewModel.shareLocation(location)
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Button {
                            showingMap = true
                        } label: {
                            Label("View on Map", systemImage: "map")
                        }
                        
                        Button {
                            exploreViewModel.getDirections(to: location)
                        } label: {
                            Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingMap) {
                LocationMapView(location: location)
            }
            .onAppear {
                loadEcoAlternatives()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Category image/icon
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: location.category.color),
                                Color(hex: location.category.color).opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 200)
                
                VStack(spacing: 16) {
                    Image(systemName: location.category.icon)
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(.white.opacity(0.9))
                    
                    VStack(spacing: 4) {
                        Text(location.category.rawValue)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(exploreViewModel.getOpeningStatus(for: location))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            
            // Title and badges
            VStack(spacing: 8) {
                HStack {
                    Text(location.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    if location.isEcoFriendly {
                        EcoBadge(score: exploreViewModel.getEcoScore(for: location))
                    }
                }
                
                HStack {
                    // Rating
                    HStack(spacing: 4) {
                        ForEach(0..<5) { star in
                            Image(systemName: star < Int(location.rating) ? "star.fill" : "star")
                                .foregroundColor(Color(hex: "#fcc418"))
                                .font(.system(size: 16))
                        }
                        
                        Text(String(format: "%.1f", location.rating))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Price level
                    Text(location.priceLevel.rawValue)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "#fcc418").opacity(0.2))
                        )
                        .foregroundColor(Color(hex: "#fcc418"))
                }
            }
        }
    }
    
    private var locationInfoSection: some View {
        HStack(spacing: 20) {
            InfoItem(
                icon: "location.fill",
                title: "Distance",
                value: exploreViewModel.formatDistance(to: location),
                color: "#4ecdc4"
            )
            
            InfoItem(
                icon: "clock.fill",
                title: "Visit Time",
                value: exploreViewModel.formatVisitDuration(location.estimatedVisitDuration),
                color: "#fcc418"
            )
            
            InfoItem(
                icon: "dollarsign.circle.fill",
                title: "Price Level",
                value: exploreViewModel.getPriceLevelDescription(location.priceLevel),
                color: "#ff6b6b"
            )
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(location.description)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(4)
        }
    }
    
    private var detailsSection: some View {
        VStack(spacing: 16) {
            // Opening hours
            if !location.openingHours.isEmpty {
                DetailCard(
                    icon: "clock.circle.fill",
                    title: "Opening Hours",
                    content: location.openingHours.joined(separator: "\n"),
                    color: "#fcc418"
                )
            }
            
            // Tags
            if !location.tags.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Features")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(location.tags, id: \.self) { tag in
                            TagView(tag: tag)
                        }
                    }
                }
            }
        }
    }
    
    private var ecoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "leaf.circle.fill")
                    .foregroundColor(Color(hex: "#3cc45b"))
                    .font(.title2)
                
                Text("Eco-Friendly")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                // Eco score
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Environmental Rating")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(exploreViewModel.getEcoScoreDescription(exploreViewModel.getEcoScore(for: location)))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        ForEach(0..<5) { star in
                            Image(systemName: star < exploreViewModel.getEcoScore(for: location) ? "leaf.fill" : "leaf")
                                .foregroundColor(Color(hex: "#3cc45b"))
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Material.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color(hex: "#3cc45b").opacity(0.3), lineWidth: 1)
                        )
                )
                
                // Carbon footprint
                if let footprint = location.carbonFootprint {
                    HStack {
                        Image(systemName: "cloud.fill")
                            .foregroundColor(Color(hex: "#3cc45b"))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Carbon Footprint")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text(String(format: "%.1f kg CO₂ per visit", footprint))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Text(footprint < 2.0 ? "Low Impact" : "Moderate Impact")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: footprint < 2.0 ? "#3cc45b" : "#fcc418").opacity(0.2))
                            )
                            .foregroundColor(Color(hex: footprint < 2.0 ? "#3cc45b" : "#fcc418"))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Material.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
    
    private var ecoAlternativesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Eco-Friendly Alternatives")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(ecoAlternatives) { alternative in
                        EcoAlternativeCard(location: alternative) {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                exploreViewModel.selectLocation(alternative)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Primary actions
            HStack(spacing: 16) {
                Button("Add to Itinerary") {
                    itineraryViewModel.addDestinationToCurrentItinerary(location)
                    // Show success feedback
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color(hex: "#3cc45b"))
                )
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                
                Button("Get Directions") {
                    exploreViewModel.getDirections(to: location)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Material.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color(hex: "#fcc418"), lineWidth: 2)
                        )
                )
                .foregroundColor(Color(hex: "#fcc418"))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            
            // Secondary actions
            HStack(spacing: 16) {
                SecondaryActionButton(
                    icon: "map.circle",
                    title: "View Map",
                    color: "#4ecdc4"
                ) {
                    showingMap = true
                }
                
                SecondaryActionButton(
                    icon: "square.and.arrow.up",
                    title: "Share",
                    color: "#ff6b6b"
                ) {
                    exploreViewModel.shareLocation(location)
                }
                
                SecondaryActionButton(
                    icon: exploreViewModel.isFavorite(location) ? "heart.circle.fill" : "heart.circle",
                    title: exploreViewModel.isFavorite(location) ? "Favorited" : "Favorite",
                    color: "#5f27cd"
                ) {
                    exploreViewModel.toggleFavorite(for: location)
                }
            }
        }
    }
    
    private func loadEcoAlternatives() {
        ecoAlternatives = exploreViewModel.getEcoAlternatives(for: location)
    }
}

struct EcoBadge: View {
    let score: Int
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Material.ultraThinMaterial)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "#3cc45b").opacity(0.5), lineWidth: 2)
                    )
                
                VStack(spacing: 2) {
                    HStack(spacing: 1) {
                        ForEach(0..<score) { _ in
                            Image(systemName: "leaf.fill")
                                .foregroundColor(Color(hex: "#3cc45b"))
                                .font(.system(size: 6))
                        }
                    }
                    
                    Text("\(score)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#3cc45b"))
                }
            }
            
            Text("Eco Score")
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

struct InfoItem: View {
    let icon: String
    let title: String
    let value: String
    let color: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(hex: color))
            
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct DetailCard: View {
    let icon: String
    let title: String
    let content: String
    let color: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: color))
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(content)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(2)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct TagView: View {
    let tag: String
    
    var body: some View {
        Text(tag)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#fcc418").opacity(0.2))
            )
            .foregroundColor(Color(hex: "#fcc418"))
    }
}

struct EcoAlternativeCard: View {
    let location: JCLocation
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "leaf.circle.fill")
                        .foregroundColor(Color(hex: "#3cc45b"))
                        .font(.title3)
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(Color(hex: "#fcc418"))
                            .font(.system(size: 10))
                        
                        Text(String(format: "%.1f", location.rating))
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Text(location.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(location.category.rawValue)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                
                if let footprint = location.carbonFootprint {
                    Text("\(String(format: "%.1f", footprint)) kg CO₂")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "#3cc45b"))
                }
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 140)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color(hex: "#3cc45b").opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// SecondaryActionButton is defined in ItineraryDetailView.swift

// MARK: - Location Map View
struct LocationMapView: View {
    let location: JCLocation
    @Environment(\.dismiss) private var dismiss
    @State private var region: MKCoordinateRegion
    
    init(location: JCLocation) {
        self.location = location
        _region = State(initialValue: MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        NavigationView {
            Map(coordinateRegion: $region, annotationItems: [location]) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    VStack {
                        ZStack {
                            Circle()
                                .fill(Color(hex: location.category.color))
                                .frame(width: 30, height: 30)
                                .shadow(radius: 3)
                            
                            Image(systemName: location.category.icon)
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .bold))
                        }
                        
                        Text(location.name)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Material.ultraThinMaterial)
                            )
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle(location.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ExploreDetailView(
        location: JCLocation(
            name: "Central Park",
            description: "Beautiful urban park perfect for morning jogs and picnics",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            category: .nature,
            rating: 4.7,
            priceLevel: .free,
            isEcoFriendly: true,
            carbonFootprint: 0.0,
            estimatedVisitDuration: 7200,
            openingHours: ["6:00 AM - 1:00 AM"],
            tags: ["outdoor", "peaceful", "jogging"]
        )
    )
    .environmentObject(ExploreViewModel(locationService: LocationService(), userPreferences: UserPreferences()))
    .environmentObject(ItineraryViewModel(itineraryService: ItineraryService(), locationService: LocationService()))
}
