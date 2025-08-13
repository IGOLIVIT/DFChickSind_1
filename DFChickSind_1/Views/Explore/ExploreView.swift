//
//  ExploreView.swift
//  JourneyCraft
//
//  Created by IGOR on 09/08/2025.
//

import SwiftUI

struct ExploreView: View {
    @EnvironmentObject private var viewModel: ExploreViewModel
    @EnvironmentObject private var itineraryViewModel: ItineraryViewModel
    @State private var showingLocationDetail = false
    @State private var selectedLocation: JCLocation?
    @State private var showingLocationPermissionAlert = false
    
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
                    LazyVStack(spacing: 20) {
                        // Header section
                        headerSection
                        
                        // Search section
                        searchSection
                        
                        // Featured locations
                        if !viewModel.featuredLocations.isEmpty {
                            featuredSection
                        }
                        
                        // Categories
                        categoriesSection
                        
                        // Search results or nearby locations
                        if !viewModel.searchText.isEmpty {
                            searchResultsSection
                        } else {
                            nearbyLocationsSection
                        }
                        
                        // Eco-friendly locations
                        if !viewModel.ecoFriendlyLocations.isEmpty {
                            ecoFriendlySection
                        }
                    }
                    .padding()
                }
                .refreshable {
                    // Refresh locations
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingLocationDetail) {
                if let location = selectedLocation {
                    ExploreDetailView(location: location)
                        .environmentObject(viewModel)
                        .environmentObject(itineraryViewModel)
                }
            }
            .alert("Location Access Denied", isPresented: $showingLocationPermissionAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Open Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            } message: {
                Text("JourneyCraft needs access to your location to find nearby places and provide personalized recommendations. Please enable location access in Settings.")
            }
            .onReceive(viewModel.locationService.$locationPermissionDenied) { denied in
                if denied {
                    showingLocationPermissionAlert = true
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Discover")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Amazing places around you")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Location stats
                let stats = viewModel.getExploreStatistics()
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: "#3cc45b").opacity(0.5), lineWidth: 2)
                            )
                        
                        Text("\(stats.totalLocations)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#3cc45b"))
                    }
                    
                    Text("Places")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
    
    private var searchSection: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.6))
                
                TextField("Search places, activities...", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                
                if viewModel.isSearching {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
            
            // Search radius slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Search Radius")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.searchRadius / 1000)) km")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "#fcc418"))
                }
                
                Slider(value: Binding(
                    get: { viewModel.searchRadius },
                    set: { viewModel.updateSearchRadius($0) }
                ), in: 1000...20000, step: 1000)
                .accentColor(Color(hex: "#fcc418"))
            }
        }
    }
    
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Featured")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(viewModel.featuredLocations.count) places")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.featuredLocations) { location in
                        FeaturedLocationCard(location: location) {
                            selectedLocation = location
                            showingLocationDetail = true
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Categories")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(JCLocation.LocationCategory.allCases, id: \.self) { category in
                    CategoryButton(category: category) {
                        viewModel.searchByCategory(category)
                    }
                }
            }
        }
    }
    
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Search Results")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                if !viewModel.searchResults.isEmpty {
                    Text("\(viewModel.searchResults.count) found")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            if viewModel.isSearching {
                SearchLoadingView()
            } else if viewModel.searchResults.isEmpty {
                EmptySearchView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.searchResults) { location in
                        LocationCard(location: location) {
                            selectedLocation = location
                            showingLocationDetail = true
                        }
                        .environmentObject(viewModel)
                    }
                }
            }
        }
    }
    
    private var nearbyLocationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Nearby")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                if !viewModel.nearbyLocations.isEmpty {
                    Text("\(viewModel.nearbyLocations.count) places")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            if viewModel.isLoading {
                LocationsLoadingView()
            } else if viewModel.nearbyLocations.isEmpty {
                EmptyNearbyView {
                    viewModel.requestLocationPermission()
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.nearbyLocations) { location in
                        LocationCard(location: location) {
                            selectedLocation = location
                            showingLocationDetail = true
                        }
                        .environmentObject(viewModel)
                    }
                }
            }
        }
    }
    
    private var ecoFriendlySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(Color(hex: "#3cc45b"))
                    .font(.title2)
                
                Text("Eco-Friendly")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(viewModel.ecoFriendlyLocations.count) places")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.ecoFriendlyLocations) { location in
                        EcoLocationCard(location: location) {
                            selectedLocation = location
                            showingLocationDetail = true
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct FeaturedLocationCard: View {
    let location: JCLocation
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                // Image placeholder with category icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
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
                        .frame(height: 120)
                    
                    Image(systemName: location.category.icon)
                        .font(.system(size: 30, weight: .light))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(location.category.rawValue)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack {
                        // Rating
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(Color(hex: "#fcc418"))
                                .font(.system(size: 12))
                            
                            Text(String(format: "%.1f", location.rating))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        // Eco badge
                        if location.isEcoFriendly {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(Color(hex: "#3cc45b"))
                                .font(.system(size: 12))
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 200)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct CategoryButton: View {
    let category: JCLocation.LocationCategory
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(hex: category.color).opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(hex: category.color))
                }
                
                Text(category.rawValue.split(separator: " ").first?.capitalized ?? category.rawValue)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LocationCard: View {
    let location: JCLocation
    let action: () -> Void
    @EnvironmentObject private var viewModel: ExploreViewModel
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(Color(hex: location.category.color).opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: location.category.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(hex: location.category.color))
                }
                
                // Location info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(location.name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Add to itinerary button
                        Button {
                            viewModel.addToItinerary(location)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color(hex: "#3cc45b"))
                                .font(.system(size: 18))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Text(location.description)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                    
                    HStack {
                        // Rating
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(Color(hex: "#fcc418"))
                                .font(.system(size: 12))
                            
                            Text(String(format: "%.1f", location.rating))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        // Price level
                        Text(location.priceLevel.rawValue)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(hex: "#fcc418").opacity(0.2))
                            )
                            .foregroundColor(Color(hex: "#fcc418"))
                        
                        // Distance
                        Text(viewModel.formatDistance(to: location))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        // Eco badge
                        if location.isEcoFriendly {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(Color(hex: "#3cc45b"))
                                .font(.system(size: 12))
                        }
                    }
                }
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct EcoLocationCard: View {
    let location: JCLocation
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "leaf.circle.fill")
                        .foregroundColor(Color(hex: "#3cc45b"))
                        .font(.title2)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(Color(hex: "#fcc418"))
                                .font(.system(size: 10))
                            
                            Text(String(format: "%.1f", location.rating))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                
                Text(location.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(location.category.rawValue)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                
                if let footprint = location.carbonFootprint {
                    HStack {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(Color(hex: "#3cc45b"))
                            .font(.system(size: 10))
                        
                        Text(String(format: "%.1f kg CO₂", footprint))
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "#3cc45b"))
                        
                        Spacer()
                    }
                }
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 160)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color(hex: "#3cc45b").opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Loading and Empty States
struct SearchLoadingView: View {
    var body: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
                .tint(.white)
            
            Text("Searching...")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct LocationsLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<3) { _ in
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black.opacity(0.2))
                    .frame(height: 80)
                    .redacted(reason: .placeholder)
            }
        }
    }
}

struct EmptySearchView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.5))
            
            VStack(spacing: 4) {
                Text("No Results Found")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Try adjusting your search terms or increasing the search radius.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct EmptyNearbyView: View {
    let onEnableLocation: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.circle")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.5))
            
            VStack(spacing: 4) {
                Text("No Nearby Places")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Enable location services to discover amazing places around you.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Button("Enable Location") {
                onEnableLocation()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "#3cc45b"))
            )
            .foregroundColor(.white)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    ExploreView()
        .environmentObject(ExploreViewModel(locationService: LocationService(), userPreferences: UserPreferences()))
        .environmentObject(ItineraryViewModel(itineraryService: ItineraryService(), locationService: LocationService()))
}
