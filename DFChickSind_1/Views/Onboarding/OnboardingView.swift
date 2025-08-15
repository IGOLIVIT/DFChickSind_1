//
//  OnboardingView.swift
//  JourneyCraft
//
//  Created by IGOR on 09/08/2025.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var userPreferences: UserPreferences
    @EnvironmentObject private var locationService: LocationService
    @State private var currentPage = 0
    @State private var showingPermissions = false
    
    private let pages = OnboardingPage.allPages
    
    var body: some View {
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
            
            // Content
            VStack(spacing: 0) {
                // Progress indicator
                HStack {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .frame(width: 8, height: 8)
                            .foregroundColor(index <= currentPage ? Color(hex: "#fcc418") : Color.white.opacity(0.3))
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 20)
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.5), value: currentPage)
                
                // Navigation buttons
                HStack(spacing: 20) {
                    if currentPage > 0 {
                        Button("Previous") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                    }
                    
                    Spacer()
                    
                    if currentPage < pages.count - 1 {
                        Button("Next") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color(hex: "#fcc418"))
                        )
                        .foregroundColor(.black)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    } else {
                        Button("Get Started") {
                            showingPermissions = true
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color(hex: "#3cc45b"))
                        )
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showingPermissions) {
            PermissionsView()
                .environmentObject(userPreferences)
                .environmentObject(locationService)
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let primaryColor: String
    let secondaryColor: String
    let features: [String]
    
    static let allPages = [
        OnboardingPage(
            title: "Welcome to",
            subtitle: "JourneyCraft",
            description: "Your personal travel companion for creating unforgettable experiences while traveling responsibly.",
            imageName: "map.circle.fill",
            primaryColor: "#fcc418",
            secondaryColor: "#3cc45b",
            features: ["Smart itinerary planning", "Eco-friendly suggestions", "Local experiences", "Real-time navigation"]
        ),
        OnboardingPage(
            title: "Smart",
            subtitle: "Itinerary Builder",
            description: "Create personalized travel plans based on your preferences, interests, and travel style.",
            imageName: "list.bullet.circle.fill",
            primaryColor: "#3cc45b",
            secondaryColor: "#fcc418",
            features: ["Smart recommendations", "Customizable preferences", "Optimized routes", "Time management"]
        ),
        OnboardingPage(
            title: "Intelligent",
            subtitle: "Navigation Alerts",
            description: "Stay informed with real-time alerts about traffic, weather, and travel tips during your journey.",
            imageName: "bell.circle.fill",
            primaryColor: "#4ecdc4",
            secondaryColor: "#fcc418",
            features: ["Traffic updates", "Weather alerts", "Safety notifications", "Route optimization"]
        ),
        OnboardingPage(
            title: "Discover",
            subtitle: "Local Experiences",
            description: "Find hidden gems and authentic local experiences based on your interests and current location.",
            imageName: "star.circle.fill",
            primaryColor: "#ff6b6b",
            secondaryColor: "#3cc45b",
            features: ["Hidden local gems", "Location-based search", "Cultural experiences", "Authentic discoveries"]
        ),
        OnboardingPage(
            title: "Green Travel",
            subtitle: "Insights",
            description: "Make sustainable choices with eco-friendly suggestions and carbon footprint tracking.",
            imageName: "leaf.circle.fill",
            primaryColor: "#3cc45b",
            secondaryColor: "#fcc418",
            features: ["Carbon footprint tracking", "Eco-friendly alternatives", "Sustainable transport", "Environmental impact"]
        )
    ]
}

#Preview {
    OnboardingView()
        .environmentObject(UserPreferences())
        .environmentObject(LocationService())
}



