//
//  NavigationMapView.swift
//  JourneyCraft
//
//  Created by IGOR on 09/08/2025.
//

import SwiftUI
import MapKit

struct NavigationMapView: View {
    @EnvironmentObject private var viewModel: NavigationViewModel
    @EnvironmentObject private var locationService: LocationService
    @State private var showingRouteOptions = false
    @State private var selectedTransportType = UserPreferences.TransportationType.mixed
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map
                Map(coordinateRegion: $viewModel.mapRegion, showsUserLocation: true, annotationItems: mapAnnotations) { annotation in
                    MapAnnotation(coordinate: annotation.coordinate) {
                        MapAnnotationView(annotation: annotation)
                    }
                }
                .ignoresSafeArea(edges: .top)
                .onAppear {
                    viewModel.centerMapOnCurrentLocation()
                }
                
                // Overlay controls
                VStack {
                    Spacer()
                    
                    // Route information card
                    if viewModel.currentRoute != nil {
                        routeInformationCard
                            .padding(.horizontal)
                    }
                    
                    // Control panel
                    controlPanel
                        .padding(.horizontal)
                        .padding(.bottom)
                }
            }
            .navigationTitle("Navigation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            viewModel.centerMapOnCurrentLocation()
                        } label: {
                            Label("Center on Location", systemImage: "location")
                        }
                        
                        if viewModel.currentRoute != nil {
                            Button {
                                viewModel.centerMapOnRoute()
                            } label: {
                                Label("Show Full Route", systemImage: "map")
                            }
                        }
                        
                        Button {
                            showingRouteOptions = true
                        } label: {
                            Label("Route Options", systemImage: "arrow.triangle.swap")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingRouteOptions) {
                RouteOptionsView(selectedTransportType: $selectedTransportType)
                    .environmentObject(viewModel)
            }
        }
    }
    
    private var mapAnnotations: [MapAnnotationData] {
        var annotations: [MapAnnotationData] = []
        
        // Current location
        if let location = locationService.currentLocation {
            annotations.append(MapAnnotationData(
                id: "current_location",
                coordinate: location.coordinate,
                type: .currentLocation,
                title: "Your Location",
                subtitle: nil
            ))
        }
        
        // Route waypoints
        if let route = viewModel.currentRoute {
            annotations.append(MapAnnotationData(
                id: "destination",
                coordinate: route.destination,
                type: .destination,
                title: "Destination",
                subtitle: nil
            ))
            
            for (index, waypoint) in route.waypoints.enumerated() {
                annotations.append(MapAnnotationData(
                    id: "waypoint_\(index)",
                    coordinate: waypoint,
                    type: .waypoint,
                    title: "Waypoint \(index + 1)",
                    subtitle: nil
                ))
            }
        }
        
        return annotations
    }
    
    private var routeInformationCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Route Information")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                if viewModel.isNavigating {
                    Button("Stop") {
                        viewModel.stopNavigation()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(hex: "#ff6b6b"))
                    )
                    .foregroundColor(.white)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                }
            }
            
            HStack(spacing: 20) {
                RouteInfoItem(
                    icon: "clock.fill",
                    title: "Duration",
                    value: viewModel.getFormattedDuration(),
                    color: "#fcc418"
                )
                
                RouteInfoItem(
                    icon: "location.fill",
                    title: "Distance",
                    value: viewModel.getFormattedDistance(),
                    color: "#4ecdc4"
                )
                
                RouteInfoItem(
                    icon: "leaf.fill",
                    title: "CO₂",
                    value: viewModel.getFormattedCarbonFootprint(),
                    color: "#3cc45b"
                )
            }
            
            if !viewModel.getFormattedETA().isEmpty {
                HStack {
                    Image(systemName: "flag.checkered")
                        .foregroundColor(Color(hex: "#3cc45b"))
                        .font(.system(size: 14))
                    
                    Text("Arriving at \(viewModel.getFormattedETA())")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var controlPanel: some View {
        HStack(spacing: 16) {
            // Navigation toggle
            Button {
                if viewModel.isNavigating {
                    viewModel.stopNavigation()
                } else {
                    // Start navigation to a sample destination
                    let sampleDestination = CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
                    viewModel.startNavigation(to: sampleDestination, transportationType: selectedTransportType)
                }
            } label: {
                HStack {
                    Image(systemName: viewModel.isNavigating ? "stop.circle.fill" : "play.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                    
                    Text(viewModel.isNavigating ? "Stop" : "Navigate")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(viewModel.isNavigating ? Color(hex: "#ff6b6b") : Color(hex: "#3cc45b"))
                )
            }
            
            // Transport type selector
            Menu {
                ForEach(UserPreferences.TransportationType.allCases, id: \.self) { type in
                    Button {
                        selectedTransportType = type
                    } label: {
                        HStack {
                            Image(systemName: type.icon)
                            Text(type.rawValue)
                            if selectedTransportType == type {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: selectedTransportType.icon)
                        .font(.system(size: 18, weight: .medium))
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Material.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            // Center location button
            Button {
                viewModel.centerMapOnCurrentLocation()
            } label: {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color(hex: "#fcc418"))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Material.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
        }
    }
}

struct MapAnnotationData: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let type: AnnotationType
    let title: String
    let subtitle: String?
    
    enum AnnotationType {
        case currentLocation
        case destination
        case waypoint
        case pointOfInterest
    }
}

struct MapAnnotationView: View {
    let annotation: MapAnnotationData
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 30, height: 30)
                    .shadow(radius: 3)
                
                Image(systemName: iconName)
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .bold))
            }
            
            if !annotation.title.isEmpty {
                Text(annotation.title)
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
    
    private var backgroundColor: Color {
        switch annotation.type {
        case .currentLocation:
            return Color(hex: "#4ecdc4")
        case .destination:
            return Color(hex: "#ff6b6b")
        case .waypoint:
            return Color(hex: "#fcc418")
        case .pointOfInterest:
            return Color(hex: "#3cc45b")
        }
    }
    
    private var iconName: String {
        switch annotation.type {
        case .currentLocation:
            return "location.fill"
        case .destination:
            return "flag.fill"
        case .waypoint:
            return "circle.fill"
        case .pointOfInterest:
            return "star.fill"
        }
    }
}

struct RouteInfoItem: View {
    let icon: String
    let title: String
    let value: String
    let color: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: color))
            
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

struct RouteOptionsView: View {
    @Binding var selectedTransportType: UserPreferences.TransportationType
    @EnvironmentObject private var viewModel: NavigationViewModel
    @Environment(\.dismiss) private var dismiss
    
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
                        // Transport type selection
                        transportTypeSection
                        
                        // Alternative routes
                        alternativeRoutesSection
                        
                        // Eco-friendly options
                        ecoFriendlySection
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Route Options")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private var transportTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transportation Mode")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(UserPreferences.TransportationType.allCases, id: \.self) { type in
                    TransportTypeCard(
                        type: type,
                        isSelected: selectedTransportType == type
                    ) {
                        selectedTransportType = type
                    }
                }
            }
        }
    }
    
    private var alternativeRoutesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Alternative Routes")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            let alternatives = viewModel.getAlternativeRoutes()
            
            if alternatives.isEmpty {
                Text("No alternative routes available")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(alternatives.enumerated()), id: \.offset) { index, route in
                        AlternativeRouteCard(route: route) {
                            viewModel.selectAlternativeRoute(route)
                            dismiss()
                        }
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
                
                Text("Eco-Friendly Options")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            let ecoRoutes = viewModel.getEcoFriendlyRoutes()
            
            if ecoRoutes.isEmpty {
                EcoTipCard()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(ecoRoutes.enumerated()), id: \.offset) { index, route in
                        EcoRouteCard(route: route) {
                            viewModel.selectAlternativeRoute(route)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

struct TransportTypeCard: View {
    let type: UserPreferences.TransportationType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? Color(hex: "#fcc418") : .white.opacity(0.7))
                
                Text(type.rawValue)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                // Eco rating
                HStack(spacing: 2) {
                    ForEach(0..<type.ecoRating) { _ in
                        Image(systemName: "leaf.fill")
                            .foregroundColor(Color(hex: "#3cc45b"))
                            .font(.system(size: 8))
                    }
                }
            }
            .padding()
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isSelected ? Color(hex: "#fcc418") : .white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AlternativeRouteCard: View {
    let route: NavigationService.Route.AlternativeRoute
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(route.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .foregroundColor(.white.opacity(0.6))
                                .font(.system(size: 12))
                            
                            Text(formatDuration(route.duration))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "location")
                                .foregroundColor(.white.opacity(0.6))
                                .font(.system(size: 12))
                            
                            Text(formatDistance(route.distance))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if route.isEcoFriendly {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(Color(hex: "#3cc45b"))
                            .font(.system(size: 16))
                    }
                    
                    Text(String(format: "%.1f kg CO₂", route.carbonFootprint))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let km = distance / 1000.0
        return String(format: "%.1f km", km)
    }
}

struct EcoRouteCard: View {
    let route: NavigationService.Route.AlternativeRoute
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: "leaf.circle.fill")
                    .foregroundColor(Color(hex: "#3cc45b"))
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(route.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Low carbon footprint route")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f kg CO₂", route.carbonFootprint))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#3cc45b"))
                    
                    Text("saved")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
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

struct EcoTipCard: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(Color(hex: "#fcc418"))
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Go Green!")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Choose walking, cycling, or public transport to reduce your carbon footprint.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color(hex: "#fcc418").opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    NavigationMapView()
        .environmentObject(NavigationViewModel(navigationService: NavigationService(locationService: LocationService()), locationService: LocationService()))
        .environmentObject(LocationService())
}
