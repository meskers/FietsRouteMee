//
//  OfflineNavigationView.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 08/10/2025.
//

import SwiftUI
import MapKit
import CoreLocation

struct OfflineNavigationView: View {
    @StateObject private var navigationManager = OfflineNavigationManager()
    @Environment(\.dismiss) private var dismiss
    let route: BikeRoute
    
    @State private var showingInstructions = false
    @State private var isFullScreen = false
    @State private var showingVoiceSettings = false
    
    var body: some View {
        ZStack {
            // Map Background
            Map {
                // Show route polyline
                MapPolyline(coordinates: route.polyline)
                    .stroke(.blue, lineWidth: 4)
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
            
            // Navigation Overlay
            VStack {
                // Top Status Bar
                if !isFullScreen {
                TopStatusBar(
                    route: route,
                    navigationManager: navigationManager,
                    showingVoiceSettings: $showingVoiceSettings
                )
                }
                
                Spacer()
                
                // Bottom Navigation Card
                BottomNavigationCard(
                    navigationManager: navigationManager,
                    showingInstructions: $showingInstructions,
                    isFullScreen: $isFullScreen,
                    showingVoiceSettings: $showingVoiceSettings
                )
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            navigationManager.startNavigation(for: route)
        }
        .onDisappear {
            navigationManager.stopNavigation()
        }
        .sheet(isPresented: $showingInstructions) {
            NavigationInstructionsView(navigationManager: navigationManager)
        }
        .sheet(isPresented: $showingVoiceSettings) {
            SettingsView()
        }
    }
    
    private func regionForRoute(_ route: BikeRoute) -> MKCoordinateRegion {
        let coordinates = route.polyline
        let minLat = coordinates.map(\.latitude).min() ?? route.startLocation.latitude
        let maxLat = coordinates.map(\.latitude).max() ?? route.endLocation.latitude
        let minLng = coordinates.map(\.longitude).min() ?? route.startLocation.longitude
        let maxLng = coordinates.map(\.longitude).max() ?? route.endLocation.longitude
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.01) * 1.2,
            longitudeDelta: max(maxLng - minLng, 0.01) * 1.2
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
}

struct TopStatusBar: View {
    let route: BikeRoute
    @ObservedObject var navigationManager: OfflineNavigationManager
    @Binding var showingVoiceSettings: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .background(.black.opacity(0.3), in: Circle())
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("Offline Navigatie")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("\(route.formattedDistance) • \(route.formattedDuration)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button(action: { showingVoiceSettings = true }) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .background(.black.opacity(0.3), in: Circle())
            }
        }
        .padding()
        .background(.black.opacity(0.3))
    }
}

struct BottomNavigationCard: View {
    @ObservedObject var navigationManager: OfflineNavigationManager
    @Binding var showingInstructions: Bool
    @Binding var isFullScreen: Bool
    @Binding var showingVoiceSettings: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress Bar
            ProgressView(value: navigationManager.navigationProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .scaleEffect(x: 1, y: 2)
            
            VStack(spacing: 16) {
                // Current Instruction
                if let instruction = navigationManager.currentInstruction {
                    CurrentInstructionCard(instruction: instruction)
                }
                
                // Distance and Time Info
                DistanceTimeInfo(navigationManager: navigationManager)
                
                // Action Buttons
                ActionButtons(
                    showingInstructions: $showingInstructions,
                    isFullScreen: $isFullScreen,
                    showingVoiceSettings: $showingVoiceSettings,
                    navigationManager: navigationManager
                )
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}

struct CurrentInstructionCard: View {
    let instruction: RouteInstruction
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconForInstruction(instruction.type))
                .font(.title)
                .foregroundColor(.green)
                .frame(width: 40, height: 40)
                .background(.green.opacity(0.1), in: Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(instruction.instruction)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                
                if instruction.distance > 0 {
                    Text("\(Int(instruction.distance))m")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func iconForInstruction(_ type: RouteInstruction.InstructionType) -> String {
        switch type {
        case .start: return "play.circle.fill"
        case .turnLeft: return "arrow.turn.up.left"
        case .turnRight: return "arrow.turn.up.right"
        case .straight: return "arrow.up"
        case .destination: return "flag.circle.fill"
        case .roundabout: return "arrow.clockwise"
        case .uTurn: return "arrow.uturn.backward"
        }
    }
}

struct DistanceTimeInfo: View {
    @ObservedObject var navigationManager: OfflineNavigationManager
    
    var body: some View {
        HStack(spacing: 20) {
            DistanceTimeItem(
                icon: "ruler",
                value: "\(Int(navigationManager.distanceToNextTurn))m",
                label: "Naar volgende bocht"
            )
            
            DistanceTimeItem(
                icon: "clock",
                value: formatTime(navigationManager.estimatedTimeToDestination),
                label: "Naar bestemming"
            )
            
            DistanceTimeItem(
                icon: "speedometer",
                value: "18 km/h",
                label: "Gem. snelheid"
            )
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
}

struct DistanceTimeItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ActionButtons: View {
    @Binding var showingInstructions: Bool
    @Binding var isFullScreen: Bool
    @Binding var showingVoiceSettings: Bool
    @ObservedObject var navigationManager: OfflineNavigationManager
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: { navigationManager.previousInstruction() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(.blue, in: Circle())
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { showingInstructions = true }) {
                VStack(spacing: 4) {
                    Image(systemName: "list.bullet")
                        .font(.title2)
                    Text("Instructies")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.green, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { showingVoiceSettings = true }) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(.purple, in: Circle())
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { isFullScreen.toggle() }) {
                Image(systemName: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(.orange, in: Circle())
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { navigationManager.nextInstruction() }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(.blue, in: Circle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct NavigationInstructionsView: View {
    @ObservedObject var navigationManager: OfflineNavigationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(navigationManager.routeInstructions.enumerated()), id: \.offset) { index, instruction in
                    NavigationInstructionRow(
                        instruction: instruction,
                        isCurrent: index == navigationManager.currentInstructionIndex
                    )
                }
            }
            .navigationTitle("Navigatie Instructies")
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


struct NavigationInstructionRow: View {
    let instruction: RouteInstruction
    let isCurrent: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForInstruction(instruction.type))
                .font(.title3)
                .foregroundColor(isCurrent ? .green : .blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(instruction.instruction)
                    .font(.body)
                    .foregroundColor(isCurrent ? .primary : .secondary)
                Text(RouteFormatter.formatDistance(instruction.distance))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if isCurrent {
                Spacer()
                Image(systemName: "location.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
        .background(isCurrent ? Color.green.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
    
    private func iconForInstruction(_ type: RouteInstruction.InstructionType) -> String {
        switch type {
        case .start: return "flag.fill"
        case .turnLeft: return "arrow.turn.up.left"
        case .turnRight: return "arrow.turn.up.right"
        case .straight: return "arrow.up"
        case .destination: return "mappin.and.ellipse"
        case .roundabout: return "arrow.triangle.2.circlepath"
        case .uTurn: return "arrow.uturn.left"
        }
    }
}

#Preview {
    OfflineNavigationView(route: BikeRoute(
        startLocation: CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041),
        endLocation: CLLocationCoordinate2D(latitude: 52.3702, longitude: 4.8952),
        waypoints: [],
        distance: 2500,
        duration: 900,
        elevation: [0, 5, 10, 8, 12],
        instructions: [
            RouteInstruction(instruction: "Ga rechtdoor", distance: 500, coordinate: CLLocationCoordinate2D(latitude: 52.3680, longitude: 4.9030), type: .straight),
            RouteInstruction(instruction: "Sla linksaf", distance: 300, coordinate: CLLocationCoordinate2D(latitude: 52.3690, longitude: 4.9000), type: .turnLeft),
            RouteInstruction(instruction: "Bestemming bereikt", distance: 0, coordinate: CLLocationCoordinate2D(latitude: 52.3702, longitude: 4.8952), type: .destination)
        ],
        polyline: [
            CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041),
            CLLocationCoordinate2D(latitude: 52.3680, longitude: 4.9030),
            CLLocationCoordinate2D(latitude: 52.3690, longitude: 4.9000),
            CLLocationCoordinate2D(latitude: 52.3702, longitude: 4.8952)
        ],
        difficulty: .easy,
        surface: .asphalt,
        createdAt: Date(),
        isFavorite: false
    ))
}
