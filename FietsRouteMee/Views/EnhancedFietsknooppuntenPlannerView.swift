//
//  EnhancedFietsknooppuntenPlannerView.swift
//  FietsRouteMee
//
//  Enhanced Dutch Cycling Junction Planner with real-time data
//

import SwiftUI
import MapKit
import CoreLocation

struct EnhancedFietsknooppuntenPlannerView: View {
    @StateObject private var fietsknooppuntenService = FietsknooppuntenService.shared
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var routeManager = RouteManager.shared
    
    @State private var selectedStartKnooppunt: Fietsknooppunt?
    @State private var selectedEndKnooppunt: Fietsknooppunt?
    @State private var calculatedRoute: FietsknooppuntRoute?
    @State private var showingRouteDetails = false
    @State private var searchText = ""
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041), // Amsterdam
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with search
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "bicycle")
                            .foregroundColor(.green)
                            .font(.title2)
                        
                        Text("Fietsknooppunten Planner")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                    }
                    
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Zoek knooppunt...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: searchText) { _, newValue in
                                searchKnooppunten(query: newValue)
                            }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                
                // Map view
                EnhancedMapView(
                    region: $region,
                    routes: .constant([]),
                    selectedRoute: .constant(nil),
                    knooppunten: $fietsknooppuntenService.knooppunten,
                    cyclingPOIs: .constant([]),
                    showKnooppunten: true,
                    showCyclingPOIs: false
                )
                .frame(maxHeight: .infinity)
                .onChange(of: region) { _, newRegion in
                    Task {
                        await fietsknooppuntenService.loadKnooppunten(in: newRegion)
                    }
                }
                
                // Bottom panel
                VStack(spacing: 16) {
                    // Selected knooppunten
                    HStack(spacing: 20) {
                        // Start knooppunt
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Start")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let start = selectedStartKnooppunt {
                                HStack {
                                    Circle()
                                        .fill(.green)
                                        .frame(width: 12, height: 12)
                                    
                                    Text(start.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            } else {
                                Text("Selecteer start")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Arrow
                        Image(systemName: "arrow.right")
                            .foregroundColor(.blue)
                            .font(.title3)
                        
                        Spacer()
                        
                        // End knooppunt
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Eind")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let end = selectedEndKnooppunt {
                                HStack {
                                    Text(end.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Circle()
                                        .fill(.red)
                                        .frame(width: 12, height: 12)
                                }
                            } else {
                                Text("Selecteer eind")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        // Clear selection
                        Button(action: clearSelection) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Wissen")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.quaternary)
                            .cornerRadius(10)
                        }
                        .disabled(selectedStartKnooppunt == nil && selectedEndKnooppunt == nil)
                        
                        // Calculate route
                        Button(action: calculateRoute) {
                            HStack {
                                Image(systemName: "route")
                                Text("Bereken Route")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canCalculateRoute ? .blue : .gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(!canCalculateRoute)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await fietsknooppuntenService.loadKnooppunten(in: region)
                }
            }
            .sheet(isPresented: $showingRouteDetails) {
                if let route = calculatedRoute {
                    FietsknooppuntRouteDetailsView(route: route)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canCalculateRoute: Bool {
        selectedStartKnooppunt != nil && selectedEndKnooppunt != nil
    }
    
    private var filteredKnooppunten: [Fietsknooppunt] {
        if searchText.isEmpty {
            return fietsknooppuntenService.knooppunten
        } else {
            return fietsknooppuntenService.knooppunten.filter { knooppunt in
                knooppunt.number.contains(searchText) ||
                knooppunt.name?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    // MARK: - Actions
    
    private func searchKnooppunten(query: String) {
        // Search is handled by filteredKnooppunten computed property
    }
    
    private func clearSelection() {
        selectedStartKnooppunt = nil
        selectedEndKnooppunt = nil
        calculatedRoute = nil
    }
    
    private func calculateRoute() {
        guard let start = selectedStartKnooppunt,
              let end = selectedEndKnooppunt else { return }
        
        Task {
            if let route = await fietsknooppuntenService.findRoute(from: start, to: end) {
                calculatedRoute = route
                showingRouteDetails = true
            }
        }
    }
}

// MARK: - Route Details View

struct FietsknooppuntRouteDetailsView: View {
    let route: FietsknooppuntRoute
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Route header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Fietsknooppunten Route")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(route.routeDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Route stats
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
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
                            title: "Moeilijkheid",
                            value: route.difficulty.displayName,
                            icon: "chart.bar",
                            color: .orange
                        )
                        
                        StatCard(
                            title: "Ondergrond",
                            value: route.surface.displayName,
                            icon: "road.lanes",
                            color: .purple
                        )
                    }
                    
                    // Waypoints
                    if !route.waypoints.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Knooppunten")
                                .font(.headline)
                            
                            ForEach(route.waypoints, id: \.id) { knooppunt in
                                HStack {
                                    Circle()
                                        .fill(.blue)
                                        .frame(width: 8, height: 8)
                                    
                                    Text(knooppunt.displayName)
                                        .font(.subheadline)
                                    
                                    Spacer()
                                    
                                    Text(knooppunt.network.displayName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: startNavigation) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Start Navigatie")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button(action: saveRoute) {
                            HStack {
                                Image(systemName: "heart")
                                Text("Opslaan als Favoriet")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Route Details")
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
    
    private func startNavigation() {
        // Convert FietsknooppuntRoute to BikeRoute and start navigation
        let bikeRoute = convertToBikeRoute(route)
        RouteManager.shared.routes.append(bikeRoute)
        // Start navigation logic here
    }
    
    private func saveRoute() {
        // Save route as favorite
        let bikeRoute = convertToBikeRoute(route)
        CoreDataManager.shared.saveRoute(bikeRoute)
    }
    
    private func convertToBikeRoute(_ route: FietsknooppuntRoute) -> BikeRoute {
        let coordinates = [route.start.coordinate] + route.waypoints.map(\.coordinate) + [route.end.coordinate]
        
        return BikeRoute(
            startLocation: route.start.coordinate,
            endLocation: route.end.coordinate,
            waypoints: route.waypoints.map(\.coordinate),
            distance: route.distance,
            duration: route.estimatedDuration,
            elevation: [],
            instructions: [],
            polyline: coordinates,
            difficulty: route.difficulty,
            surface: route.surface,
            bikeType: .city,
            createdAt: route.createdAt,
            isFavorite: true
        )
    }
}

#Preview {
    EnhancedFietsknooppuntenPlannerView()
}
