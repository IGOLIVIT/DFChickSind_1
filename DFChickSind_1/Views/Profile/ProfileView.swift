//
//  ProfileView.swift
//  JourneyCraft
//
//  Created by IGOR on 09/08/2025.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var userPreferences: UserPreferences
    @EnvironmentObject private var itineraryViewModel: ItineraryViewModel
    @EnvironmentObject private var navigationService: NavigationService
    @EnvironmentObject private var locationService: LocationService
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#3e4464"),
                        Color(hex: "#2d3142")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        profileHeaderSection
                        
                        // Personal Info
                        personalInfoSection
                        
                        // Travel Statistics
                        statisticsSection
                        
                        // Preferences
                        preferencesSection
                        
                        // Account Management
                        accountManagementSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        saveProfile()
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing {
                            saveProfile()
                        }
                        isEditing.toggle()
                    }
                    .foregroundColor(Color(hex: "#fcc418"))
                }
            }
        }
                    .onAppear {
                firstName = userPreferences.firstName
                lastName = userPreferences.lastName
            }
            .alert("Delete Account", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("This action cannot be undone. All your data including itineraries, preferences, and saved locations will be permanently deleted. Are you sure you want to delete your account?")
            }
    }
    
    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            // Profile Avatar
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#fcc418"),
                            Color(hex: "#3cc45b")
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .overlay(
                    Text(profileInitials)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 4) {
                Text(fullName)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Travel Explorer")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personal Information")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                ProfileTextField(
                    title: "First Name",
                    text: $firstName,
                    isEditing: isEditing,
                    placeholder: "Enter your first name"
                )
                
                ProfileTextField(
                    title: "Last Name",
                    text: $lastName,
                    isEditing: isEditing,
                    placeholder: "Enter your last name"
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.2))
            )
        }
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Travel Statistics")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            let stats = itineraryViewModel.getStatistics()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatisticCard(
                    title: "Total Trips",
                    value: "\(stats.totalTrips)",
                    icon: "suitcase.fill",
                    color: "#3cc45b"
                )
                
                StatisticCard(
                    title: "Places Visited",
                    value: "\(stats.totalDestinations)",
                    icon: "location.fill",
                    color: "#fcc418"
                )
                
                StatisticCard(
                    title: "Eco Trips",
                    value: "\(stats.ecoFriendlyTrips)",
                    icon: "leaf.fill",
                    color: "#4ecdc4"
                )
                
                StatisticCard(
                    title: "Total Distance",
                    value: "\(Int(stats.totalDistance)) km",
                    icon: "road.lanes",
                    color: "#ff6b6b"
                )
            }
        }
    }
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Travel Preferences")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                PreferenceRow(
                    title: "Travel Style",
                    value: userPreferences.travelStyle.rawValue,
                    icon: userPreferences.travelStyle.icon
                )
                
                PreferenceRow(
                    title: "Transportation",
                    value: userPreferences.preferredTransportation.rawValue,
                    icon: userPreferences.preferredTransportation.icon
                )
                
                PreferenceRow(
                    title: "Eco Mode",
                    value: userPreferences.ecoFriendlyMode ? "Enabled" : "Disabled",
                    icon: "leaf.circle"
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.2))
            )
        }
    }
    
    private var profileInitials: String {
        let first = firstName.prefix(1).uppercased()
        let last = lastName.prefix(1).uppercased()
        return "\(first)\(last)"
    }
    
    private var fullName: String {
        if firstName.isEmpty && lastName.isEmpty {
            return "Traveler"
        }
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    private var accountManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account Management")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Button(action: {
                showingDeleteAlert = true
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Delete Account")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Permanently delete all your data")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.red.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func saveProfile() {
        userPreferences.firstName = firstName
        userPreferences.lastName = lastName
        userPreferences.savePreferences()
    }
    
    private func deleteAccount() {
        // Clear all app data
        userPreferences.resetAllData()
        
        // Clear itinerary data
        itineraryViewModel.clearAllData()
        
        // Clear navigation data
        navigationService.clearAllData()
        
        // Clear location data
        locationService.clearAllData()
        
        // The app will automatically navigate to onboarding because hasCompletedOnboarding is now false
    }
}

struct ProfileTextField: View {
    let title: String
    @Binding var text: String
    let isEditing: Bool
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            
            if isEditing {
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "#fcc418"), lineWidth: 1)
                    )
                    .foregroundColor(.white)
            } else {
                Text(text.isEmpty ? "Not set" : text)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(text.isEmpty ? .white.opacity(0.5) : .white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.05))
                    )
            }
        }
    }
}

struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(Color(hex: color))
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.2))
        )
    }
}

struct PreferenceRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(hex: "#fcc418"))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
    }
}

#Preview {
    let locationService = LocationService()
    let navigationService = NavigationService(locationService: locationService)
    let itineraryService = ItineraryService()
    
    ProfileView()
        .environmentObject(UserPreferences())
        .environmentObject(ItineraryViewModel(itineraryService: itineraryService, locationService: locationService))
        .environmentObject(navigationService)
        .environmentObject(locationService)
}
