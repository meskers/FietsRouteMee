//
//  RouteCard.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 08/10/2025.
//

import SwiftUI
import CoreLocation

struct RouteCard: View {
    let route: BikeRoute
    @Binding var showingDetails: Bool
    @ObservedObject var routeManager: RouteManager
    @ObservedObject var locationManager: LocationManager
    @State private var showingNavigation = false
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            
            VStack(spacing: 16) {
                // Route info header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fietsroute")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(route.formattedDistance) • \(route.formattedDuration)")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    // Difficulty indicator
                    DifficultyBadge(difficulty: route.difficulty)
                }
                
                // Route stats
                HStack(spacing: 20) {
                    StatItem(
                        icon: "speedometer",
                        value: String(format: "%.1f km/h", route.averageSpeed),
                        label: "Gem. snelheid"
                    )
                    
                    StatItem(
                        icon: "arrow.up.arrow.down",
                        value: "\(Int(route.elevation.max() ?? 0))m",
                        label: "Hoogste punt"
                    )
                    
                    StatItem(
                        icon: "road.lanes",
                        value: route.surface.displayName,
                        label: "Ondergrond"
                    )
                }
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: { showingDetails = true }) {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("Details")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(action: { 
                        print("🚴‍♂️ RouteCard: Start navigation button tapped")
                        showingNavigation = true 
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.green, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .padding(.bottom, 20)
        .scaleEffect(isAnimating ? 1.0 : 0.9)
        .opacity(isAnimating ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
        .fullScreenCover(isPresented: $showingNavigation) {
            TurnByTurnNavigationView(
                routeManager: routeManager,
                locationManager: locationManager,
                voiceManager: VoiceNavigationManager.shared
            )
        }
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DifficultyBadge: View {
    let difficulty: RouteDifficulty
    
    var body: some View {
        Text(difficulty.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(difficulty.color), in: Capsule())
    }
}

#Preview {
    VStack {
        Spacer()
        RouteCard(route: BikeRoute(
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
        ), showingDetails: .constant(false), routeManager: RouteManager.shared, locationManager: LocationManager.shared)
    }
    .background(Color.gray.opacity(0.1))
}
