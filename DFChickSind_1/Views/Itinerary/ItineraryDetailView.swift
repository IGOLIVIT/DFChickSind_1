//
//  ItineraryDetailView.swift
//  JourneyCraft
//
//  Created by IGOR on 09/08/2025.
//

import SwiftUI
import UIKit

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    static let full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }()
}
import MapKit

struct ItineraryDetailView: View {
    let itinerary: Itinerary
    @EnvironmentObject private var viewModel: ItineraryViewModel
    @EnvironmentObject private var navigationViewModel: NavigationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingMap = false
    @State private var showingDeleteAlert = false

    @State private var selectedDestination: JCLocation?
    
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
                        
                        // Journey info
                        journeyInfoSection
                        
                        // Destinations
                        destinationsSection
                        
                        // Environmental impact
                        environmentalSection
                        
                        // Action buttons
                        actionButtonsSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle(itinerary.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.title2)
                    }
                }
            }
            .alert("Delete Journey", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.deleteItinerary(itinerary)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete '\(itinerary.title)'? This action cannot be undone.")
            }
            .sheet(isPresented: $showingMap) {
                ItineraryMapView(itinerary: itinerary)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Journey title and status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(itinerary.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(viewModel.getItineraryStatusDescription(itinerary))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "#fcc418"))
                }
                
                Spacer()
                
                // Eco badge
                if itinerary.isEcoFriendly {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(Material.ultraThinMaterial)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(Color(hex: "#3cc45b").opacity(0.5), lineWidth: 2)
                                )
                            
                            Image(systemName: "leaf.fill")
                                .foregroundColor(Color(hex: "#3cc45b"))
                                .font(.title2)
                        }
                        
                        Text("Eco-Friendly")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "#3cc45b"))
                    }
                }
            }
            
            // Description
            if !itinerary.description.isEmpty {
                Text(itinerary.description)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(2)
            }
        }
    }
    
    private var journeyInfoSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Journey Information")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                InfoCard(
                    title: "Duration",
                    value: itinerary.formattedDuration,
                    icon: "clock.fill",
                    color: "#fcc418"
                )
                
                InfoCard(
                    title: "Distance",
                    value: viewModel.formatDistance(itinerary.totalDistance),
                    icon: "location.fill",
                    color: "#4ecdc4"
                )
                
                InfoCard(
                    title: "Destinations",
                    value: "\(itinerary.destinations.count)",
                    icon: "star.fill",
                    color: "#ff6b6b"
                )
                
                InfoCard(
                    title: "Cost",
                    value: viewModel.formatCost(itinerary.estimatedCost),
                    icon: "dollarsign.circle.fill",
                    color: "#3cc45b"
                )
            }
        }
    }
    
    private var destinationsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Destinations")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View on Map") {
                    showingMap = true
                }
                .foregroundColor(Color(hex: "#fcc418"))
                .font(.system(size: 14, weight: .medium, design: .rounded))
            }
            
            if itinerary.destinations.isEmpty {
                EmptyDestinationsView {
                    // Add destination action
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(itinerary.destinations.enumerated()), id: \.element.id) { index, destination in
                        DestinationCard(
                            destination: destination,
                            index: index,
                            isFirst: index == 0,
                            isLast: index == itinerary.destinations.count - 1
                        ) {
                            selectedDestination = destination
                        }
                    }
                }
            }
        }
    }
    
    private var environmentalSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Environmental Impact")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Carbon footprint
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(Color(hex: "#3cc45b"))
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Carbon Footprint")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(viewModel.formatCarbonFootprint(itinerary.estimatedCarbonFootprint))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Eco rating
                    HStack(spacing: 4) {
                        ForEach(0..<5) { star in
                            Image(systemName: star < itinerary.ecoFriendlyScore ? "star.fill" : "star")
                                .foregroundColor(Color(hex: "#3cc45b"))
                                .font(.system(size: 14))
                        }
                    }
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
                
                // Eco tips
                if itinerary.isEcoFriendly {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "#3cc45b"))
                        
                        Text("This journey follows eco-friendly practices")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Primary action
            Button("Start Navigation") {
                startNavigation()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(hex: "#3cc45b"))
            )
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold, design: .rounded))
        }
    }
    
    private func startNavigation() {
        navigationViewModel.startNavigation(for: itinerary)
        if let firstDestination = itinerary.destinations.first {
            navigationViewModel.setCurrentDestination(firstDestination)
        }
    }
    
    private func shareItinerary() {
        let shareText = """
        🗺️ \(itinerary.title)
        
        \(itinerary.description)
        
        📅 \(DateFormatter.shortDate.string(from: itinerary.startDate)) - \(DateFormatter.shortDate.string(from: itinerary.endDate))
        
        📍 Destinations: \(itinerary.destinations.map { $0.name }.joined(separator: ", "))
        
        🌱 Estimated Carbon Footprint: \(String(format: "%.1f", itinerary.estimatedCarbonFootprint)) kg CO₂
        
        Created with JourneyCraft ✈️
        """
        
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func exportItinerary() {
        let exportData = """
        JOURNEYCRAFT ITINERARY EXPORT
        
        Title: \(itinerary.title)
        Description: \(itinerary.description)
        Start Date: \(DateFormatter.full.string(from: itinerary.startDate))
        End Date: \(DateFormatter.full.string(from: itinerary.endDate))
        
        DESTINATIONS:
        \(itinerary.destinations.enumerated().map { index, destination in
            "\(index + 1). \(destination.name) - \(destination.category)"
        }.joined(separator: "\n"))
        
        SUSTAINABILITY:
        Carbon Footprint: \(String(format: "%.1f", itinerary.estimatedCarbonFootprint)) kg CO₂
        Distance: \(String(format: "%.1f", itinerary.totalDistance)) km
        
        Exported on \(DateFormatter.full.string(from: Date()))
        """
        
        let activityVC = UIActivityViewController(activityItems: [exportData], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(Color(hex: color))
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
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

struct DestinationCard: View {
    let destination: JCLocation
    let index: Int
    let isFirst: Bool
    let isLast: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Timeline indicator
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 2, height: 20)
                }
                
                ZStack {
                    Circle()
                        .fill(Color(hex: destination.category.color))
                        .frame(width: 24, height: 24)
                    
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                if !isLast {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 2, height: 20)
                }
            }
            
            // Destination info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(destination.name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(destination.category.rawValue)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Rating
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(Color(hex: "#fcc418"))
                            .font(.system(size: 12))
                        
                        Text(String(format: "%.1f", destination.rating))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                HStack {
                    // Price level
                    Text(destination.priceLevel.rawValue)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "#fcc418").opacity(0.2))
                        )
                        .foregroundColor(Color(hex: "#fcc418"))
                    
                    if destination.isEcoFriendly {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(Color(hex: "#3cc45b"))
                            .font(.system(size: 12))
                    }
                    
                    Spacer()
                }
            }
            .padding(.vertical, 8)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}

struct EmptyDestinationsView: View {
    let addAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "map.circle")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.5))
            
            Text("No destinations added yet")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
            
            Button("Add Destination") {
                addAction()
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



// MARK: - Itinerary Map View
struct ItineraryMapView: View {
    let itinerary: Itinerary
    @Environment(\.dismiss) private var dismiss
    @State private var region: MKCoordinateRegion
    
    init(itinerary: Itinerary) {
        self.itinerary = itinerary
        
        // Calculate region to show all destinations
        if !itinerary.destinations.isEmpty {
            let coordinates = itinerary.destinations.map { $0.coordinate }
            
            // Safe calculations with validation
            guard let minLat = coordinates.map({ $0.latitude }).min(),
                  let maxLat = coordinates.map({ $0.latitude }).max(),
                  let minLon = coordinates.map({ $0.longitude }).min(),
                  let maxLon = coordinates.map({ $0.longitude }).max(),
                  minLat.isFinite, maxLat.isFinite, minLon.isFinite, maxLon.isFinite else {
                // Fallback to default region if coordinates are invalid
                _region = State(initialValue: MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
                return
            }
            
            let centerLat = (minLat + maxLat) / 2
            let centerLon = (minLon + maxLon) / 2
            
            // Validate center coordinates
            guard centerLat.isFinite && centerLon.isFinite else {
                _region = State(initialValue: MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
                return
            }
            
            let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
            
            let latDelta = max(0.01, (maxLat - minLat) * 1.3)
            let lonDelta = max(0.01, (maxLon - minLon) * 1.3)
            
            // Validate span values
            guard latDelta.isFinite && lonDelta.isFinite && latDelta > 0 && lonDelta > 0 else {
                _region = State(initialValue: MKCoordinateRegion(
                    center: center,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
                return
            }
            
            let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            _region = State(initialValue: MKCoordinateRegion(center: center, span: span))
        } else {
            // Default region for empty destinations
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }
    
    var body: some View {
        NavigationView {
            Map(coordinateRegion: $region, annotationItems: itinerary.destinations) { destination in
                MapAnnotation(coordinate: destination.coordinate) {
                    VStack {
                        ZStack {
                            Circle()
                                .fill(Color(hex: destination.category.color))
                                .frame(width: 30, height: 30)
                            
                            Image(systemName: destination.category.icon)
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .bold))
                        }
                        .shadow(radius: 3)
                        
                        Text(destination.name)
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
            .navigationTitle(itinerary.title)
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
    ItineraryDetailView(
        itinerary: Itinerary(
            title: "Weekend in San Francisco",
            description: "A beautiful weekend exploring the best of SF",
            destinations: [],
            travelStyle: .balanced
        )
    )
    .environmentObject(ItineraryViewModel(itineraryService: ItineraryService(), locationService: LocationService()))
    .environmentObject(NavigationViewModel(navigationService: NavigationService(locationService: LocationService()), locationService: LocationService()))
}
