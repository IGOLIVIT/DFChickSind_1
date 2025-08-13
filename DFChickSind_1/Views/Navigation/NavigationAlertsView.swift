//
//  NavigationAlertsView.swift
//  JourneyCraft
//
//  Created by IGOR on 09/08/2025.
//

import SwiftUI

struct NavigationAlertsView: View {
    @EnvironmentObject private var viewModel: NavigationViewModel
    @State private var selectedAlertType: NavigationService.NavigationAlert.AlertType?
    @State private var showingAlertDetail = false
    
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
                        // Header with quick stats
                        headerSection
                        
                        // Alert type filters
                        alertTypeFiltersSection
                        
                        // Active alerts
                        activeAlertsSection
                        
                        // Navigation status
                        navigationStatusSection
                        
                        // Weather and traffic info
                        conditionsSection
                    }
                    .padding()
                }
                .refreshable {
                    // Refresh alerts
                }
            }
            .navigationTitle("Smart Alerts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            viewModel.dismissAllAlerts()
                        } label: {
                            Label("Clear All Alerts", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stay Informed")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Real-time travel intelligence")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Alert count badge
                let alertCounts = viewModel.getAlertCounts()
                if alertCounts.total > 0 {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(Material.ultraThinMaterial)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(Color(hex: "#fcc418").opacity(0.5), lineWidth: 2)
                                )
                            
                            Text("\(alertCounts.total)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#fcc418"))
                        }
                        
                        Text("Active")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            
            // Quick stats
            let alertCounts = viewModel.getAlertCounts()
            HStack(spacing: 16) {
                AlertStatCard(
                    title: "High Priority",
                    count: alertCounts.high,
                    icon: "exclamationmark.triangle.fill",
                    color: "#ff6b6b"
                )
                
                AlertStatCard(
                    title: "Eco Tips",
                    count: alertCounts.eco,
                    icon: "leaf.fill",
                    color: "#3cc45b"
                )
                
                AlertStatCard(
                    title: "Total Today",
                    count: alertCounts.total,
                    icon: "bell.fill",
                    color: "#fcc418"
                )
            }
        }
    }
    
    private var alertTypeFiltersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filter by Type")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    AlertTypeFilter(
                        type: nil,
                        title: "All",
                        isSelected: selectedAlertType == nil
                    ) {
                        selectedAlertType = nil
                    }
                    
                    ForEach([
                        NavigationService.NavigationAlert.AlertType.traffic,
                        .weather,
                        .safety,
                        .ecoTip,
                        .routeOptimization,
                        .pointOfInterest
                    ], id: \.self) { type in
                        AlertTypeFilter(
                            type: type,
                            title: alertTypeTitle(type),
                            isSelected: selectedAlertType == type
                        ) {
                            selectedAlertType = type
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var activeAlertsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Active Alerts")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                if !filteredAlerts.isEmpty {
                    Text("\(filteredAlerts.count) alerts")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            if filteredAlerts.isEmpty {
                EmptyAlertsView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredAlerts) { alert in
                        NavigationAlertCard(alert: alert) {
                            viewModel.selectAlert(alert)
                        } dismissAction: {
                            viewModel.dismissAlert(alert)
                        }
                    }
                }
            }
        }
    }
    
    private var navigationStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Navigation Status")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            HStack {
                Image(systemName: viewModel.isNavigating ? "location.fill" : "location.circle")
                    .foregroundColor(viewModel.isNavigating ? Color(hex: "#3cc45b") : .white.opacity(0.6))
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.getNavigationStatus())
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if viewModel.isNavigating {
                        HStack(spacing: 16) {
                            if !viewModel.getFormattedETA().isEmpty {
                                Text("ETA: \(viewModel.getFormattedETA())")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            if !viewModel.getFormattedDuration().isEmpty {
                                Text("Duration: \(viewModel.getFormattedDuration())")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    } else {
                        Text("Ready to navigate")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                if viewModel.isNavigating {
                    Button("Stop") {
                        viewModel.stopNavigation()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "#ff6b6b"))
                    )
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
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
        }
    }
    
    private var conditionsSection: some View {
        VStack(spacing: 16) {
            // Weather conditions
            VStack(alignment: .leading, spacing: 12) {
                Text("Current Conditions")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                HStack(spacing: 16) {
                    // Weather
                    ConditionCard(
                        title: "Weather",
                        value: viewModel.getWeatherDescription(),
                        icon: viewModel.getWeatherIcon(),
                        color: viewModel.shouldShowWeatherAlert() ? "#ff6b6b" : "#4ecdc4"
                    )
                    
                    // Traffic
                    ConditionCard(
                        title: "Traffic",
                        value: viewModel.getTrafficDescription(),
                        icon: "car.fill",
                        color: viewModel.getTrafficColor()
                    )
                }
            }
        }
    }
    
    private var filteredAlerts: [NavigationService.NavigationAlert] {
        if let selectedType = selectedAlertType {
            return viewModel.getAlertsByType(selectedType)
        } else {
            return viewModel.activeAlerts.sorted { $0.timestamp > $1.timestamp }
        }
    }
    
    private func alertTypeTitle(_ type: NavigationService.NavigationAlert.AlertType) -> String {
        switch type {
        case .traffic: return "Traffic"
        case .weather: return "Weather"
        case .safety: return "Safety"
        case .ecoTip: return "Eco Tips"
        case .routeOptimization: return "Routes"
        case .pointOfInterest: return "Points"
        }
    }
}

struct AlertStatCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(hex: color))
            
            Text("\(count)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct AlertTypeFilter: View {
    let type: NavigationService.NavigationAlert.AlertType?
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let type = type {
                    Image(systemName: type.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? .black : .white.opacity(0.8))
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .black : .white.opacity(0.8))
            }
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
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NavigationAlertCard: View {
    let alert: NavigationService.NavigationAlert
    let action: () -> Void
    let dismissAction: () -> Void
    @EnvironmentObject private var viewModel: NavigationViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Alert icon
            ZStack {
                Circle()
                    .fill(Color(hex: alert.type.color).opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: alert.type.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(hex: alert.type.color))
            }
            
            // Alert content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(alert.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Priority badge
                    if alert.priority == .high || alert.priority == .critical {
                        Text(viewModel.getPriorityDisplayText(alert.priority))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(alert.priority == .critical ? Color(hex: "#ff6b6b") : Color(hex: "#fcc418"))
                            )
                            .foregroundColor(.white)
                    }
                }
                
                Text(alert.message)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(3)
                
                HStack {
                    Text(viewModel.formatAlertTime(alert.timestamp))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    // Action button
                    if let suggestedAction = alert.suggestedAction {
                        Button(suggestedAction) {
                            action()
                        }
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "#3cc45b"))
                    }
                }
            }
            
            // Dismiss button
            Button {
                dismissAction()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white.opacity(0.4))
                    .font(.system(size: 20))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color(hex: alert.type.color).opacity(0.3), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}

struct ConditionCard: View {
    let title: String
    let value: String
    let icon: String
    let color: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(Color(hex: color))
            
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
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

struct EmptyAlertsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash.circle")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.5))
            
            VStack(spacing: 4) {
                Text("No Active Alerts")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("You're all set! We'll notify you of any important updates.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
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

#Preview {
    NavigationAlertsView()
        .environmentObject(NavigationViewModel(navigationService: NavigationService(locationService: LocationService()), locationService: LocationService()))
}
