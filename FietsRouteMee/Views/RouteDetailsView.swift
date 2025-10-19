//
//  RouteDetailsView.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 08/10/2025.
//

import SwiftUI
import MapKit

struct RouteDetailsView: View {
    let route: BikeRoute
    @ObservedObject var routeManager: RouteManager
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var voiceManager: VoiceNavigationManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var showingNavigation = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Tab", selection: $selectedTab) {
                    Text("Overzicht").tag(0)
                    Text("Instructies").tag(1)
                    Text("Hoogteprofiel").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    OverviewTab(route: route)
                        .tag(0)
                    
                    InstructionsTab(route: route)
                        .tag(1)
                    
                    ElevationTab(route: route)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Route Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Sluiten") {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Sluiten")
                    .accessibilityHint("Tik om terug te gaan naar de kaart")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Start Navigatie") {
                        print("🚴‍♂️ RouteDetailsView: Start Navigatie button tapped")
                        print("🚴‍♂️ RouteDetailsView: Route available: true")
                        showingNavigation = true
                    }
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
                    .buttonStyle(.plain)
                    .accessibilityLabel("Start navigatie")
                    .accessibilityHint("Tik om turn-by-turn navigatie te starten")
                }
            }
        }
        .fullScreenCover(isPresented: $showingNavigation) {
            TurnByTurnNavigationView(
                routeManager: routeManager,
                locationManager: locationManager,
                voiceManager: voiceManager
            )
        }
    }
}

struct OverviewTab: View {
    let route: BikeRoute
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Route stats
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    StatCard(
                        title: "Afstand",
                        value: route.formattedDistance,
                        icon: "ruler",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Tijd",
                        value: route.formattedDuration,
                        icon: "clock",
                        color: .green
                    )
                    
                    StatCard(
                        title: "Gem. snelheid",
                        value: String(format: "%.1f km/h", route.averageSpeed),
                        icon: "speedometer",
                        color: .orange
                    )
                    
                    StatCard(
                        title: "Moeilijkheid",
                        value: route.difficulty.displayName,
                        icon: "chart.bar",
                        color: Color(route.difficulty.color)
                    )
                }
                
                // Route map
                VStack(alignment: .leading, spacing: 12) {
                    Text("Route Kaart")
                        .font(.headline)
                    
                    Map {
                        // Route polyline
                        MapPolyline(coordinates: route.polyline)
                            .stroke(.blue, lineWidth: 4)
                        
                        // Start marker
                        Marker("Start", coordinate: route.startLocation)
                            .tint(.green)
                        
                        // End marker
                        Marker("Bestemming", coordinate: route.endLocation)
                            .tint(.red)
                    }
                    .mapStyle(.standard)
                    .frame(height: 200)
                    .cornerRadius(12)
                }
                
                // Surface info
                HStack {
                    Image(systemName: "road.lanes")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("Ondergrond")
                            .font(.headline)
                        Text(route.surface.displayName)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding()
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
    
    private func routeAnnotations(_ route: BikeRoute) -> [RouteAnnotationItem] {
        return [
            RouteAnnotationItem(
                coordinate: route.startLocation,
                color: .green,
                title: "Start"
            ),
            RouteAnnotationItem(
                coordinate: route.endLocation,
                color: .red,
                title: "Bestemming"
            )
        ]
    }
}

struct InstructionsTab: View {
    let route: BikeRoute
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(route.instructions) { instruction in
                    InstructionRow(
                        instruction: instruction,
                        isCurrent: false,
                        isCompleted: false
                    )
                }
            }
            .padding()
        }
    }
}

struct ElevationTab: View {
    let route: BikeRoute
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Elevation chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hoogteprofiel")
                        .font(.headline)
                    
                    if !route.elevation.isEmpty {
                        ElevationChart(elevation: route.elevation)
                            .frame(height: 200)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    } else {
                        Text("Geen hoogtegegevens beschikbaar")
                            .foregroundColor(.secondary)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                // Elevation stats
                if !route.elevation.isEmpty {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                        StatCard(
                            title: "Hoogste punt",
                            value: "\(Int(route.elevation.max() ?? 0))m",
                            icon: "arrow.up",
                            color: .red
                        )
                        
                        StatCard(
                            title: "Laagste punt",
                            value: "\(Int(route.elevation.min() ?? 0))m",
                            icon: "arrow.down",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Hoogteverschil",
                            value: "\(Int((route.elevation.max() ?? 0) - (route.elevation.min() ?? 0)))m",
                            icon: "arrow.up.arrow.down",
                            color: .orange
                        )
                    }
                }
            }
            .padding()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}


struct ElevationChart: View {
    let elevation: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard !elevation.isEmpty else { return }
                
                let minElevation = elevation.min() ?? 0
                let maxElevation = elevation.max() ?? 0
                let elevationRange = maxElevation - minElevation
                
                let width = geometry.size.width
                let height = geometry.size.height
                
                let stepX = width / CGFloat(elevation.count - 1)
                
                for (index, elevation) in elevation.enumerated() {
                    let x = CGFloat(index) * stepX
                    let normalizedElevation = (elevation - minElevation) / elevationRange
                    let y = height - (normalizedElevation * height)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(.blue, lineWidth: 2)
        }
    }
}

struct RouteAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let color: Color
    let title: String
}

#Preview {
    RouteDetailsView(
        route: BikeRoute(
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
        ),
        routeManager: RouteManager.shared,
        locationManager: LocationManager.shared,
        voiceManager: VoiceNavigationManager.shared
    )
}
