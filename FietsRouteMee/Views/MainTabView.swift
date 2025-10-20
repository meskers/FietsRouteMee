//
//  MainTabView.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 08/10/2025.
//

import SwiftUI
import CoreLocation

struct MainTabView: View {
    @ObservedObject private var locationManager = LocationManager.shared
    @StateObject private var routeManager = RouteManager.shared
    @StateObject private var favoritesManager = FavoritesManager()
    @StateObject private var weatherManager = WeatherManager()
    @ObservedObject private var appSettingsManager = AppSettingsManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Map Tab - Primary action tab
            MapTabView(
                locationManager: locationManager,
                routeManager: routeManager,
                weatherManager: weatherManager
            )
            .tabItem {
                Label("Kaart", systemImage: "map.fill")
            }
            .tag(0)
            
            // Discover Tab - Exploration
            DiscoverView(
                routeManager: routeManager,
                favoritesManager: favoritesManager,
                locationManager: locationManager
            )
            .tabItem {
                Label("Ontdek", systemImage: "sparkles")
            }
            .tag(1)
            
            // Routes Tab - Saved content
            RoutesView(
                routeManager: routeManager,
                locationManager: locationManager,
                favoritesManager: favoritesManager
            )
            .tabItem {
                Label("Routes", systemImage: "list.bullet.rectangle.fill")
            }
            .tag(2)
            
                    // Profile Tab - Settings & user
                    ProfileView(
                        favoritesManager: favoritesManager,
                        weatherManager: weatherManager,
                        routeManager: routeManager
                    )
            .tabItem {
                Label("Profiel", systemImage: "person.crop.circle.fill")
            }
            .tag(3)
        }
        .tint(.green) // iOS 15+ accent color
        .environmentObject(appSettingsManager)
        .onAppear {
            // Setup initial permissions and data
            Task {
                // Clear all old routes FIRST, before loading anything
                CoreDataManager.shared.clearAllData()
                print("🗑️ MainTabView: Cleared all old routes on startup")
                
                await locationManager.requestLocationPermission()
            }
        }
    }
}

struct MapTabView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var routeManager: RouteManager
    @ObservedObject var weatherManager: WeatherManager
    @ObservedObject private var appSettingsManager = AppSettingsManager.shared
    @State private var showingRouteDetails = false
    @State private var selectedRoute: BikeRoute?
    @State private var showingRouteOptions = false
    @State private var showingAdvancedPlanner = false
    @State private var pendingStartLocation: CLLocationCoordinate2D?
    @State private var pendingEndLocation: CLLocationCoordinate2D?
    
    var body: some View {
                ZStack {
                    // Main Map View
                    MapView(
                        region: $locationManager.region,
                        routes: $routeManager.routes,
                        selectedRoute: $selectedRoute,
                        pendingStartLocation: pendingStartLocation,
                        pendingEndLocation: pendingEndLocation
                    )
                    .ignoresSafeArea()
            
            // Loading Overlay
            if routeManager.isCalculating {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text("Route berekenen...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                }
                .transition(.opacity)
                .animation(.easeInOut, value: routeManager.isCalculating)
            }
            
            // Top Controls
            VStack {
                HStack {
                    // Search Button
                    Button(action: { 
                        showingAdvancedPlanner = true
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.primary)
                            Text("Waar wil je naartoe?")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Zoek bestemming")
                    .accessibilityHint("Tik om een nieuwe route te plannen")
                    
                    Spacer()
                    
                    // Location Button
                    Button(action: { 
                        Task {
                            await locationManager.centerOnUserLocation()
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(.blue, in: Circle())
                            .shadow(radius: 4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Centreren op huidige locatie")
                    .accessibilityHint("Tik om de kaart te centreren op je huidige positie")
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
                
                // Bottom Controls
                VStack(spacing: 12) {
                    // Weather Card
                    if let weather = weatherManager.currentWeather {
                        WeatherCard(weather: weather)
                    }
                    
                    // Route Card
                    if let route = selectedRoute {
                        RouteCard(
                            route: route, 
                            showingDetails: $showingRouteDetails,
                            routeManager: routeManager,
                            locationManager: locationManager
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                    // Quick Action Buttons
                    QuickActionButtons(
                        showingRouteOptions: $showingRouteOptions,
                        showingAdvancedPlanner: $showingAdvancedPlanner
                    )
                    }
                }
            }
        }
        .sheet(isPresented: $showingRouteDetails) {
            if let route = selectedRoute {
                        RouteDetailsView(
                            route: route,
                            routeManager: routeManager,
                            locationManager: locationManager,
                            voiceManager: VoiceNavigationManager.shared
                        )
            }
        }
        .sheet(isPresented: $showingRouteOptions) {
            RouteOptionsView(routeManager: routeManager)
        }
        .sheet(isPresented: $showingAdvancedPlanner) {
            AdvancedRoutePlanner(
                routeManager: routeManager, 
                locationManager: locationManager,
                onRouteGenerated: { route in
                    selectedRoute = route
                    print("🚴‍♂️ MapTabView: Route generated, setting selectedRoute")
                }
            )
        }
                .onChange(of: routeManager.routes.count) {
                    // Don't auto-select routes - let user choose manually
                    print("🚴‍♂️ MapTabView: Routes count changed to \(routeManager.routes.count)")
                }
                .onChange(of: routeManager.routes.isEmpty) {
                    // Clear selected route when routes are cleared
                    if routeManager.routes.isEmpty {
                        selectedRoute = nil
                        print("🚴‍♂️ MapTabView: Cleared selected route")
                    }
                }
                .onChange(of: routeManager.routes.count) { oldCount, newCount in
                    // Sync selectedRoute with routeManager.routes
                    if let currentSelected = selectedRoute {
                        // Check if selected route still exists in routeManager
                        if !routeManager.routes.contains(where: { $0.id == currentSelected.id }) {
                            selectedRoute = nil
                            print("🚴‍♂️ MapTabView: Selected route no longer exists, clearing")
                        }
                    }
                }
                .alert("Fout bij route berekening", isPresented: .constant(routeManager.errorMessage != nil)) {
                    Button("OK", role: .cancel) {
                        routeManager.errorMessage = nil
                    }
                } message: {
                    Text(routeManager.errorMessage ?? "")
                }
    }
}

struct QuickActionButtons: View {
    @Binding var showingRouteOptions: Bool
    @Binding var showingAdvancedPlanner: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: { 
                    showingRouteOptions = true 
                }) {
                    HStack {
                        Image(systemName: "gear.circle.fill")
                            .foregroundColor(.white)
                        Text("Route Opties")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.orange, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Route opties")
                .accessibilityHint("Tik om route instellingen te wijzigen")
                
                Button(action: { 
                    showingAdvancedPlanner = true 
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .foregroundColor(.white)
                        Text("Zoek Route")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Zoek route")
                .accessibilityHint("Tik om een nieuwe route te zoeken")
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

struct WeatherCard: View {
    let weather: WeatherData
    
    var body: some View {
        HStack {
            Image(systemName: weather.icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(weather.temperature))°C")
                    .font(.headline)
                Text(weather.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(weather.windSpeed)) km/h")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Wind")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

#Preview {
    MainTabView()
}
