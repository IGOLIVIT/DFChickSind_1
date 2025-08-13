//
//  ItineraryView.swift
//  JourneyCraft
//
//  Created by IGOR on 09/08/2025.
//

import SwiftUI

struct ItineraryView: View {
    @EnvironmentObject private var userPreferences: UserPreferences
    @EnvironmentObject private var viewModel: ItineraryViewModel
    @EnvironmentObject private var navigationService: NavigationService
    @EnvironmentObject private var locationService: LocationService
    @State private var showingCreateItinerary = false
    @State private var showingProfile = false
    @State private var searchText = ""
    
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
                        
                        // Quick stats
                        if !viewModel.itineraries.isEmpty {
                            statsSection
                        }
                        
                        // Search and filters
                        searchAndFiltersSection
                        
                        // Itineraries
                        if viewModel.filteredItineraries.isEmpty {
                            emptyStateView
                                .onAppear {
                                    print("🔍 UI: Showing empty state. Total itineraries: \(viewModel.itineraries.count), Filtered: \(viewModel.filteredItineraries.count)")
                                }
                        } else {
                            itinerariesSection
                                .onAppear {
                                    print("📱 UI: Showing \(viewModel.filteredItineraries.count) itineraries")
                                }
                        }
                    }
                    .padding()
                }
                .refreshable {
                    viewModel.loadItineraries()
                }
            }
            .navigationTitle("My Journeys")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateItinerary = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color(hex: "#fcc418"))
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingCreateItinerary) {
                CreateItineraryView()
                    .environmentObject(viewModel)
                    .environmentObject(userPreferences)
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
                    .environmentObject(userPreferences)
                    .environmentObject(viewModel)
                    .environmentObject(navigationService)
                    .environmentObject(locationService)
            }
            .onAppear {
                print("🏠 ItineraryView appeared. Current itineraries count: \(viewModel.itineraries.count)")
                viewModel.loadItineraries()
            }
            .sheet(isPresented: $viewModel.showingItineraryDetail) {
                if let itinerary = viewModel.currentItinerary {
                    ItineraryDetailView(itinerary: itinerary)
                        .environmentObject(viewModel)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back!")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Ready for your next adventure?")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Profile icon
                Button {
                    showingProfile = true
                } label: {
                    Circle()
                        .fill(Color.black.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.circle.fill")
                                .font(.title)
                                .foregroundColor(Color(hex: "#fcc418"))
                        )
                }
            }
        }
    }
    
    private var statsSection: some View {
        let stats = viewModel.getStatistics()
        
        return HStack(spacing: 16) {
            StatCard(
                title: "Trips",
                value: "\(stats.totalTrips)",
                icon: "suitcase.fill",
                color: "#3cc45b"
            )
            
            StatCard(
                title: "Places",
                value: "\(stats.totalDestinations)",
                icon: "location.fill",
                color: "#fcc418"
            )
            
            StatCard(
                title: "Eco Score",
                value: String(format: "%.1f", stats.averageRating),
                icon: "leaf.fill",
                color: "#4ecdc4"
            )
        }
    }
    
    private var searchAndFiltersSection: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.6))
                
                TextField("Search itineraries...", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
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
            
            // Filter buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ItineraryViewModel.FilterOption.allCases, id: \.self) { filter in
                        FilterButton(
                            title: filter.rawValue,
                            isSelected: viewModel.selectedFilter == filter
                        ) {
                            viewModel.selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var itinerariesSection: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.filteredItineraries) { itinerary in
                ItineraryCard(itinerary: itinerary) {
                    viewModel.selectItinerary(itinerary)
                }
                .environmentObject(viewModel)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "map.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#fcc418").opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Itineraries Yet")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Start planning your first journey to discover amazing places and experiences.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button("Create Your First Journey") {
                showingCreateItinerary = true
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(hex: "#3cc45b"))
            )
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold, design: .rounded))
        }
        .padding(.top, 60)
    }
}

struct StatCard: View {
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
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
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

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color(hex: "#fcc418") : Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? Color.clear : .white.opacity(0.3), lineWidth: 1)
                        )
                )
                .foregroundColor(isSelected ? .black : .white.opacity(0.8))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ItineraryCard: View {
    let itinerary: Itinerary
    let action: () -> Void
    @EnvironmentObject private var viewModel: ItineraryViewModel
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(itinerary.title)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        Text(viewModel.getItineraryStatusDescription(itinerary))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "#fcc418"))
                    }
                    
                    Spacer()
                    
                    // Eco badge
                    if itinerary.isEcoFriendly {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(Color(hex: "#3cc45b"))
                            .font(.system(size: 16))
                    }
                }
                
                // Stats
                HStack(spacing: 20) {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 12))
                        Text("\(itinerary.destinations.count) places")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 12))
                        Text(itinerary.formattedDuration)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 12))
                        Text(viewModel.formatCost(itinerary.estimatedCost))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                
                // Tags
                if !itinerary.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(itinerary.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(hex: "#fcc418").opacity(0.2))
                                    )
                                    .foregroundColor(Color(hex: "#fcc418"))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .contextMenu {
            Button {
                viewModel.duplicateItinerary(itinerary)
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            
            Button {
                viewModel.optimizeItinerary(itinerary)
            } label: {
                Label("Optimize Route", systemImage: "arrow.triangle.swap")
            }
            
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Journey", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteItinerary(itinerary)
            }
        } message: {
            Text("Are you sure you want to delete '\(itinerary.title)'? This action cannot be undone.")
        }
    }
}

// MARK: - Create Itinerary View
struct CreateItineraryView: View {
    @EnvironmentObject private var viewModel: ItineraryViewModel
    @EnvironmentObject private var userPreferences: UserPreferences
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var selectedStyle = UserPreferences.TravelStyle.balanced
    
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
                        // Title input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Journey Title")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            
                            TextField("Enter journey title", text: $title)
                                .textFieldStyle(GlassmorphicTextFieldStyle())
                        }
                        
                        // Date selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Travel Dates")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Start Date")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    DatePicker("", selection: $startDate, displayedComponents: .date)
                                        .datePickerStyle(CompactDatePickerStyle())
                                        .accentColor(Color(hex: "#fcc418"))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("End Date")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    DatePicker("", selection: $endDate, displayedComponents: .date)
                                        .datePickerStyle(CompactDatePickerStyle())
                                        .accentColor(Color(hex: "#fcc418"))
                                }
                            }
                        }
                        
                        // Travel style selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Travel Style")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(UserPreferences.TravelStyle.allCases, id: \.self) { style in
                                    TravelStyleCard(
                                        style: style,
                                        isSelected: selectedStyle == style
                                    ) {
                                        selectedStyle = style
                                    }
                                }
                            }
                        }
                        

                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Create Journey")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createItinerary()
                    }
                    .foregroundColor(Color(hex: "#3cc45b"))
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func createItinerary() {
        let itinerary = Itinerary(
            title: title,
            description: description,
            startDate: startDate,
            endDate: endDate,
            travelStyle: selectedStyle
        )
        viewModel.createItinerary(itinerary)
        
        // Force UI update after creation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismiss()
        }
    }
}

struct TravelStyleCard: View {
    let style: UserPreferences.TravelStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: style.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? Color(hex: "#fcc418") : .white.opacity(0.7))
                
                Text(style.rawValue)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(style.description)
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
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

struct GlassmorphicTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        return configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .foregroundColor(.white)
    }
}

#Preview {
    ItineraryView()
        .environmentObject(UserPreferences())
        .environmentObject(ItineraryViewModel(itineraryService: ItineraryService(), locationService: LocationService()))
}
