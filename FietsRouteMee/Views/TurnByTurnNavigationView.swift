//
//  TurnByTurnNavigationView.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 08/10/2025.
//

import SwiftUI
import MapKit
import CoreLocation
import AVFoundation

struct TurnByTurnNavigationView: View {
    @ObservedObject var routeManager: RouteManager
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var voiceManager: VoiceNavigationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStepIndex = 0
    @State private var distanceToNextTurn: Double = 0
    @State private var isNavigating = false
    @State private var showingRouteOverview = false
    @State private var routeProgress: Double = 0
    @State private var estimatedTimeRemaining: TimeInterval = 0
    @State private var currentSpeed: Double = 0
    @State private var currentElevation: Double = 0
    @State private var navigationTimer: Timer?
    
    private var currentRoute: BikeRoute? {
        routeManager.routes.first
    }
    
    private var currentInstruction: RouteInstruction? {
        guard let route = currentRoute,
              currentStepIndex < route.instructions.count else { return nil }
        return route.instructions[currentStepIndex]
    }
    
    private var nextInstruction: RouteInstruction? {
        guard let route = currentRoute,
              currentStepIndex + 1 < route.instructions.count else { return nil }
        return route.instructions[currentStepIndex + 1]
    }
    
    var body: some View {
        ZStack {
            // Map View with stable region for navigation
            NavigationMapView(
                region: $locationManager.region,
                routes: $routeManager.routes,
                selectedRoute: .constant(currentRoute)
            )
            .ignoresSafeArea()
            
            // Navigation UI Overlay
            VStack {
                // Top Status Bar - Modern Minimal Design
                HStack(spacing: 12) {
                    // Stop Button
                    Button {
                        stopNavigation()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.red.gradient, in: Circle())
                            .shadow(color: .red.opacity(0.3), radius: 4, y: 2)
                    }
                    
                    Spacer()
                    
                    // Speed Display - Large and Prominent
                    VStack(spacing: 0) {
                        Text("\(Int(currentSpeed))")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                currentSpeed > 0 ? 
                                    LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .top, endPoint: .bottom) :
                                    LinearGradient(colors: [.gray, .gray.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                            )
                            .contentTransition(.numericText())
                        
                        Text("km/u")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(1)
                    }
                    .frame(width: 120)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    )
                    
                    Spacer()
                    
                    // Route Overview Button
                    Button {
                        showingRouteOverview = true
                    } label: {
                        Image(systemName: "list.bullet.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.blue.gradient, in: Circle())
                            .shadow(color: .blue.opacity(0.3), radius: 4, y: 2)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer()
                
                // Current Instruction Card - Modern Turn-by-Turn Display
                if let instruction = currentInstruction {
                    VStack(spacing: 0) {
                        // Large Turn Arrow with Distance
                        HStack(spacing: 20) {
                            // Turn Icon - Large and Prominent
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.green, .green.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .shadow(color: .green.opacity(0.3), radius: 8, y: 4)
                                
                                Image(systemName: instructionTypeIcon(instruction.type))
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                // Distance to turn
                                if distanceToNextTurn > 0 {
                                    HStack(spacing: 4) {
                                        Text(formatDistance(distanceToNextTurn))
                                            .font(.system(size: 42, weight: .bold, design: .rounded))
                                            .foregroundStyle(.primary)
                                        
                                        Text(distanceToNextTurn >= 1000 ? "km" : "m")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.secondary)
                                    }
                                } else {
                                    Text("Nu")
                                        .font(.system(size: 42, weight: .bold, design: .rounded))
                                        .foregroundStyle(.orange)
                                }
                                
                                // Instruction text
                                Text(instruction.instruction)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
                        )
                        
                        // Next instruction preview (if available)
                        if let nextInstruction = nextInstruction {
                            HStack(spacing: 12) {
                                Image(systemName: instructionTypeIcon(nextInstruction.type))
                                    .font(.title3)
                                    .foregroundStyle(.white)
                                    .frame(width: 36, height: 36)
                                    .background(.secondary.opacity(0.6), in: Circle())
                                
                                Text("Daarna: \(nextInstruction.instruction)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial.opacity(0.6))
                        }
                        
                        // Progress Bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(.secondary.opacity(0.2))
                                
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.green, .green.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * routeProgress)
                            }
                        }
                        .frame(height: 4)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startNavigation()
            
            // Start timer for regular updates (store reference to invalidate later)
            navigationTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                Task { @MainActor in
                    updateNavigationProgress()
                }
            }
        }
        .onDisappear {
            stopNavigation()
            
            // Stop the timer to prevent memory leaks and excessive updates
            navigationTimer?.invalidate()
            navigationTimer = nil
        }
        .sheet(isPresented: $showingRouteOverview) {
            RouteOverviewSheet(
                route: currentRoute,
                currentStepIndex: $currentStepIndex,
                routeProgress: $routeProgress
            )
        }
    }
    
    private func startNavigation() {
        guard let route = currentRoute else { 
            print("❌ TurnByTurnNavigationView: No route available for navigation")
            return 
        }
        
        print("🚴‍♂️ TurnByTurnNavigationView: Starting navigation for route")
        isNavigating = true
        voiceManager.startNavigation(for: route)
        
        // Start location tracking for navigation
        locationManager.startLocationUpdates()
        
        // Calculate initial progress
        updateNavigationProgress()
        
        print("✅ TurnByTurnNavigationView: Navigation started successfully")
    }
    
    private func stopNavigation() {
        isNavigating = false
        voiceManager.stopNavigation()
        locationManager.stopLocationUpdates()
        
        // Clear the selected route so user can choose a new one
        routeManager.clearRoutes()
        
        print("🚴‍♂️ TurnByTurnNavigationView: Navigation stopped, returning to map")
        dismiss()
    }
    
    private func updateNavigationProgress() {
        guard let route = currentRoute,
              let userLocation = locationManager.userLocation else { return }
        
        // Find closest point on route
        var minDistance = Double.infinity
        var closestIndex = 0
        
        for (index, coordinate) in route.polyline.enumerated() {
            let distance = userLocation.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
            if distance < minDistance {
                minDistance = distance
                closestIndex = index
            }
        }
        
        // Update current step
        if closestIndex < route.instructions.count {
            currentStepIndex = closestIndex
        }
        
        // Calculate distance to next turn
        if currentStepIndex < route.instructions.count - 1 {
            let nextInstruction = route.instructions[currentStepIndex + 1]
            distanceToNextTurn = userLocation.distance(from: CLLocation(latitude: nextInstruction.coordinate.latitude, longitude: nextInstruction.coordinate.longitude))
        }
        
        // Update progress
        routeProgress = Double(closestIndex) / Double(route.polyline.count)
        
        // Update estimated time
        let remainingDistance = route.distance * (1 - routeProgress)
        estimatedTimeRemaining = remainingDistance / (currentSpeed > 0 ? currentSpeed : 15) * 3600 // Assume 15 km/h if no speed
        
        // Update current speed (convert from m/s to km/h)
        currentSpeed = (locationManager.userLocation?.speed ?? 0) * 3.6
        if currentSpeed < 0 { currentSpeed = 0 }
        
        // Update elevation - try to get from GPS first, then estimate from route
        if let altitude = locationManager.userLocation?.altitude, altitude > 0 {
            currentElevation = altitude
        } else {
            // Fallback: estimate elevation from route data
            currentElevation = estimateElevationFromRoute(userLocation: userLocation)
        }
        
        // Update map region to follow user
        updateMapRegion(for: userLocation)
    }
    
    private func updateMapRegion(for location: CLLocation) {
        // Only update region if user has moved significantly (> 50m from center)
        let currentCenter = CLLocation(latitude: locationManager.region.center.latitude, 
                                      longitude: locationManager.region.center.longitude)
        let distance = location.distance(from: currentCenter)
        
        // Only update if moved more than 50m to avoid excessive updates
        if distance > 50 {
            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 500, // 500m radius
                longitudinalMeters: 500
            )
            locationManager.region = region
        }
    }
    
    private func estimateElevationFromRoute(userLocation: CLLocation) -> Double {
        guard let route = currentRoute else { return 0 }
        
        // Try to get elevation from route data if available
        if !route.elevation.isEmpty {
            // Find closest elevation point
            let closestIndex = min(Int(routeProgress * Double(route.elevation.count)), route.elevation.count - 1)
            if closestIndex >= 0 && closestIndex < route.elevation.count {
                return route.elevation[closestIndex]
            }
        }
        
        // Fallback: estimate based on Netherlands geography
        // Amsterdam area: ~0-10m, Utrecht area: ~0-20m, hills: ~50-300m
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        
        // Rough estimation based on location
        if latitude > 52.0 && latitude < 52.5 && longitude > 4.0 && longitude < 5.5 {
            // Amsterdam/Utrecht area - mostly flat
            return Double.random(in: 0...15)
        } else if latitude > 50.5 && latitude < 52.0 {
            // Southern Netherlands - some hills
            return Double.random(in: 10...100)
        } else {
            // Default flat area
            return Double.random(in: 0...25)
        }
    }
    
    private func instructionTypeIcon(_ type: RouteInstruction.InstructionType) -> String {
        switch type {
        case .start:
            return "play.fill"
        case .turnLeft:
            return "arrow.turn.up.left"
        case .turnRight:
            return "arrow.turn.up.right"
        case .straight:
            return "arrow.up"
        case .destination:
            return "flag.fill"
        case .roundabout:
            return "arrow.clockwise"
        case .uTurn:
            return "arrow.uturn.backward"
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)u \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatTimeShort(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        
        if hours > 0 {
            return "\(hours):\(String(format: "%02d", minutes))"
        } else {
            return "\(minutes)'"
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            // Show km with 1 decimal
            return String(format: "%.1f", distance / 1000)
        } else if distance >= 100 {
            // Show rounded to nearest 10m
            return "\(Int(distance / 10) * 10)"
        } else if distance >= 50 {
            // Show rounded to nearest 10m
            return "\(Int(distance / 10) * 10)"
        } else {
            // Show exact meters for close turns
            return "\(Int(distance))"
        }
    }
}

struct RouteOverviewSheet: View {
    let route: BikeRoute?
    @Binding var currentStepIndex: Int
    @Binding var routeProgress: Double
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if let route = route {
                    // Route Stats
                    HStack {
                        VStack {
                            Text("\(Int(route.distance / 1000))")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("km")
                                .font(.caption)
                        }
                        
                        Spacer()
                        
                        VStack {
                            Text("\(Int(route.duration / 60))")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("min")
                                .font(.caption)
                        }
                        
                        Spacer()
                        
                        VStack {
                            let totalElevation = route.elevation.isEmpty ? 0 : Int(route.elevation.reduce(0, +) / Double(route.elevation.count))
                            Text("\(totalElevation)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("m avg")
                                .font(.caption)
                        }
                    }
                    .padding()
                    
                    // Instructions List
                    List(route.instructions.indices, id: \.self) { index in
                        InstructionRow(
                            instruction: route.instructions[index],
                            isCurrent: index == currentStepIndex,
                            isCompleted: index < currentStepIndex
                        )
                    }
                }
            }
            .navigationTitle("Route Overzicht")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sluiten") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InstructionRow: View {
    let instruction: RouteInstruction
    let isCurrent: Bool
    let isCompleted: Bool
    
    var body: some View {
        HStack {
            Image(systemName: instructionTypeIcon(instruction.type))
                .foregroundColor(isCurrent ? .green : (isCompleted ? .gray : .primary))
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text(instruction.instruction)
                    .font(.headline)
                    .foregroundColor(isCurrent ? .green : .primary)
                
                if instruction.distance > 0 {
                    Text("\(Int(instruction.distance))m")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isCurrent {
                Image(systemName: "location.fill")
                    .foregroundColor(.green)
            } else if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func instructionTypeIcon(_ type: RouteInstruction.InstructionType) -> String {
        switch type {
        case .start:
            return "play.fill"
        case .turnLeft:
            return "arrow.turn.up.left"
        case .turnRight:
            return "arrow.turn.up.right"
        case .straight:
            return "arrow.up"
        case .destination:
            return "flag.fill"
        case .roundabout:
            return "arrow.clockwise"
        case .uTurn:
            return "arrow.uturn.backward"
        }
    }
}

#Preview {
    TurnByTurnNavigationView(
        routeManager: RouteManager.shared,
        locationManager: LocationManager.shared,
        voiceManager: VoiceNavigationManager.shared
    )
}
