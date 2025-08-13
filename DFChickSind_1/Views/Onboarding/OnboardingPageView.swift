//
//  OnboardingPageView.swift
//  JourneyCraft
//
//  Created by IGOR on 09/08/2025.
//

import SwiftUI
import UserNotifications

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon with glassmorphism effect
            ZStack {
                // Background blur effect
                Circle()
                    .fill(Material.ultraThinMaterial)
                    .frame(width: 180, height: 180)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: page.primaryColor).opacity(0.6),
                                        Color(hex: page.secondaryColor).opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                
                // Icon
                Image(systemName: page.imageName)
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: page.primaryColor),
                                Color(hex: page.secondaryColor)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .animation(.spring(response: 0.8, dampingFraction: 0.6), value: isAnimating)
            
            // Title and subtitle
            VStack(spacing: 8) {
                if !page.title.isEmpty {
                    Text(page.title)
                        .font(.system(size: 24, weight: .light, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Text(page.subtitle)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: page.primaryColor),
                                Color(hex: page.secondaryColor)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)
            }
            .opacity(isAnimating ? 1.0 : 0.0)
            .offset(y: isAnimating ? 0 : 20)
            .animation(.easeOut(duration: 0.8).delay(0.2), value: isAnimating)
            
            // Description
            Text(page.description)
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
                .opacity(isAnimating ? 1.0 : 0.0)
                .offset(y: isAnimating ? 0 : 30)
                .animation(.easeOut(duration: 0.8).delay(0.4), value: isAnimating)
            
            Spacer()
            
            // Features list
            VStack(spacing: 16) {
                ForEach(Array(page.features.enumerated()), id: \.offset) { index, feature in
                    FeatureRow(
                        text: feature,
                        primaryColor: page.primaryColor,
                        secondaryColor: page.secondaryColor,
                        delay: Double(index) * 0.1
                    )
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .offset(x: isAnimating ? 0 : -50)
                    .animation(.easeOut(duration: 0.6).delay(0.6 + Double(index) * 0.1), value: isAnimating)
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
        .onDisappear {
            isAnimating = false
        }
    }
}

struct FeatureRow: View {
    let text: String
    let primaryColor: String
    let secondaryColor: String
    let delay: Double
    
    var body: some View {
        HStack(spacing: 15) {
            // Checkmark with glassmorphism
            ZStack {
                Circle()
                    .fill(Material.ultraThinMaterial)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(
                                Color(hex: primaryColor).opacity(0.5),
                                lineWidth: 1
                            )
                    )
                
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: primaryColor))
            }
            
            Text(text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
    }
}

// MARK: - Permissions View
struct PermissionsView: View {
    @EnvironmentObject private var userPreferences: UserPreferences
    @EnvironmentObject private var locationService: LocationService
    @Environment(\.dismiss) private var dismiss
    @State private var locationPermissionRequested = false
    @State private var notificationPermissionRequested = false
    
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
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(Color(hex: "#fcc418"))
                        
                        Text("Permissions")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("To provide you with the best experience, JourneyCraft needs access to a few features on your device.")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 40)
                    
                    // Permission cards
                    VStack(spacing: 20) {
                        PermissionCard(
                            icon: "location.circle.fill",
                            title: "Location Services",
                            description: "Find nearby attractions and provide personalized recommendations based on your location.",
                            primaryColor: "#3cc45b",
                            isGranted: locationService.isLocationEnabled,
                            action: {
                                locationPermissionRequested = true
                                locationService.requestLocationPermission()
                            }
                        )
                        
                        PermissionCard(
                            icon: "bell.circle.fill",
                            title: "Notifications",
                            description: "Receive travel alerts, weather updates, and helpful tips during your journey.",
                            primaryColor: "#fcc418",
                            isGranted: userPreferences.notificationsEnabled,
                            action: {
                                notificationPermissionRequested = true
                                requestNotificationPermission()
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                    
                    // Continue button
                    VStack(spacing: 16) {
                        Button("Continue") {
                            completeOnboarding()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color(hex: "#3cc45b"))
                        )
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        
                        Button("Skip for now") {
                            completeOnboarding()
                        }
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                userPreferences.notificationsEnabled = granted
            }
        }
    }
    
    private func completeOnboarding() {
        userPreferences.hasCompletedOnboarding = true
        userPreferences.locationPermissionGranted = locationService.isLocationEnabled
        userPreferences.savePreferences()
        dismiss()
    }
}

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let primaryColor: String
    let isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Card content
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Material.ultraThinMaterial)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .stroke(
                                        Color(hex: primaryColor).opacity(0.5),
                                        lineWidth: 1
                                    )
                            )
                        
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(Color(hex: primaryColor))
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(title)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            if isGranted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "#3cc45b"))
                                    .font(.system(size: 20))
                            }
                        }
                        
                        Text(description)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                }
                
                // Action button
                if !isGranted {
                    Button("Allow") {
                        action()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: primaryColor).opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(hex: primaryColor), lineWidth: 1)
                            )
                    )
                    .foregroundColor(Color(hex: primaryColor))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                }
            }
            .padding(20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    OnboardingPageView(page: OnboardingPage.allPages[0])
}

#Preview("Permissions") {
    PermissionsView()
        .environmentObject(UserPreferences())
        .environmentObject(LocationService())
}
