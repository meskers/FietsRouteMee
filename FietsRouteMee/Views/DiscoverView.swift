//
//  DiscoverView.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 08/10/2025.
//

import SwiftUI
import MapKit

struct DiscoverView: View {
    @ObservedObject var routeManager: RouteManager
    @ObservedObject var favoritesManager: FavoritesManager
    @ObservedObject var locationManager: LocationManager
    @State private var searchText = ""
    @State private var selectedCategory: RouteCategory = .all
    @State private var showingFilters = false
    @State private var selectedDestination: Destination?
    @State private var showingRouteDetails: BikeRoute?
    @State private var isLoadingRoute = false
    @State private var selectedTab: DiscoverTab = .featured
    
    enum DiscoverTab: String, CaseIterable {
        case featured = "Uitgelicht"
        case collections = "Collecties"
        case knooppunten = "Knooppunten"
        case activities = "Activiteiten"
    }
    
    enum RouteCategory: String, CaseIterable {
        case all = "all"
        case nature = "nature"
        case city = "city"
        case coastal = "coastal"
        case mountain = "mountain"
        
        var displayName: String {
            switch self {
            case .all: return "Alle"
            case .nature: return "Natuur"
            case .city: return "Stad"
            case .coastal: return "Kust"
            case .mountain: return "Bergen"
            }
        }
        
        var icon: String {
            switch self {
            case .all: return "globe"
            case .nature: return "leaf"
            case .city: return "building.2"
            case .coastal: return "water.waves"
            case .mountain: return "mountain.2"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Sectie", selection: $selectedTab) {
                    ForEach(DiscoverTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content based on selected tab (lazy loading for memory)
                Group {
                    switch selectedTab {
                    case .featured:
                        featuredContent
                    case .collections:
                        CollectionsView()
                    case .knooppunten:
                        KnooppuntenPlannerView()
                    case .activities:
                        ActivityTrackingView()
                    }
                }
                .id(selectedTab) // Force recreation on tab change to free memory
            }
            .navigationTitle("Ontdek")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingFilters) {
            DiscoverFiltersView(selectedCategory: $selectedCategory)
        }
        .sheet(item: $showingRouteDetails) { route in
            RouteDetailsView(
                route: route,
                routeManager: routeManager,
                locationManager: locationManager,
                voiceManager: VoiceNavigationManager.shared
            )
        }
    }
    
    // MARK: - Featured Content
    
    private var featuredContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Zoek routes...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(RouteCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Featured Routes
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(filteredRoutes.isEmpty ? "Jouw Routes" : "Aanbevolen Routes")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        if !filteredRoutes.isEmpty {
                            Text("\(filteredRoutes.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    if filteredRoutes.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "map")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            
                            Text("Nog geen routes")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Plan je eerste route via de Kaart tab")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(filteredRoutes) { route in
                                    FeaturedRouteCard(route: route)
                                        .onTapGesture {
                                            showingRouteDetails = route
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Popular Destinations
                VStack(alignment: .leading, spacing: 12) {
                    Text("Populaire Bestemmingen")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(popularDestinations) { destination in
                            DestinationCard(destination: destination)
                                .onTapGesture {
                                    selectedDestination = destination
                                    planRouteToDestination(destination)
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .overlay {
            if isLoadingRoute {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text("Route plannen...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                }
            }
        }
    }
    
    private var filteredRoutes: [BikeRoute] {
        var routes = routeManager.routes
        
        // Apply search filter
        if !searchText.isEmpty {
            routes = routes.filter { route in
                // Search in distance or duration
                route.formattedDistance.localizedCaseInsensitiveContains(searchText) ||
                route.formattedDuration.localizedCaseInsensitiveContains(searchText) ||
                route.difficulty.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply category filter
        if selectedCategory != .all {
            routes = routes.filter { route in
                switch selectedCategory {
                case .all:
                    return true
                case .nature:
                    return route.surface == .gravel || route.surface == .dirt || route.surface == .mixed
                case .city:
                    return route.surface == .asphalt && route.difficulty == .easy
                case .coastal:
                    // Check if route is near water (Netherlands coastal area)
                    return route.startLocation.latitude > 51.5 && route.startLocation.latitude < 53.5
                case .mountain:
                    return route.difficulty == .hard || route.difficulty == .expert
                }
            }
        }
        
        return routes
    }
    
    private func planRouteToDestination(_ destination: Destination) {
        guard let userLocation = locationManager.userLocation?.coordinate else {
            print("❌ No user location available")
            return
        }
        
        isLoadingRoute = true
        
        // Calculate route to destination
        routeManager.calculateRoute(
            from: userLocation,
            to: destination.coordinate
        )
        
        // Wait for route calculation
        Task {
            var attempts = 0
            let maxAttempts = 30
            
            while attempts < maxAttempts {
                try? await Task.sleep(nanoseconds: 100_000_000)
                
                await MainActor.run {
                    if !routeManager.routes.isEmpty {
                        // Show the newly calculated route
                        if let newRoute = routeManager.routes.first {
                            showingRouteDetails = newRoute
                        }
                        isLoadingRoute = false
                    } else if routeManager.errorMessage != nil {
                        isLoadingRoute = false
                    }
                }
                
                if !isLoadingRoute {
                    break
                }
                
                attempts += 1
            }
            
            if attempts >= maxAttempts {
                await MainActor.run {
                    isLoadingRoute = false
                }
            }
        }
    }
    
    private var popularDestinations: [Destination] {
        return [
            Destination(
                name: "Amsterdam Centrum",
                distance: "5.2 km",
                difficulty: .easy,
                image: "building.2",
                coordinate: CLLocationCoordinate2D(latitude: 52.3702, longitude: 4.8952)
            ),
            Destination(
                name: "Vondelpark",
                distance: "3.8 km",
                difficulty: .easy,
                image: "leaf",
                coordinate: CLLocationCoordinate2D(latitude: 52.3579, longitude: 4.8686)
            ),
            Destination(
                name: "Zuidas",
                distance: "7.1 km",
                difficulty: .moderate,
                image: "building.2",
                coordinate: CLLocationCoordinate2D(latitude: 52.3369, longitude: 4.8728)
            ),
            Destination(
                name: "IJburg",
                distance: "12.3 km",
                difficulty: .moderate,
                image: "water.waves",
                coordinate: CLLocationCoordinate2D(latitude: 52.3545, longitude: 5.0234)
            )
        ]
    }
}

// MARK: - Filters View
struct DiscoverFiltersView: View {
    @Binding var selectedCategory: DiscoverView.RouteCategory
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Categorie") {
                    ForEach(DiscoverView.RouteCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(selectedCategory == category ? .green : .primary)
                                Text(category.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedCategory == category {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Gereed") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeaturedRouteCard: View {
    let route: BikeRoute
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Route Image Placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(.green.opacity(0.2))
                .frame(width: 200, height: 120)
                .overlay(
                    VStack {
                        Image(systemName: "bicycle")
                            .font(.title)
                            .foregroundColor(.green)
                        Text("Fietsroute")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Amsterdam Route")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(route.formattedDistance) • \(route.formattedDuration)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    DifficultyBadge(difficulty: route.difficulty)
                    Spacer()
                    Text(route.surface.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct DestinationCard: View {
    let destination: Destination
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: destination.image)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Spacer()
                
                DifficultyBadge(difficulty: destination.difficulty)
            }
            
            Text(destination.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(destination.distance)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct Destination: Identifiable {
    let id = UUID()
    let name: String
    let distance: String
    let difficulty: RouteDifficulty
    let image: String
    let coordinate: CLLocationCoordinate2D
}

struct CategoryButton: View {
    let category: DiscoverView.RouteCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ? .blue : .gray.opacity(0.2),
                in: Capsule()
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


#Preview {
    DiscoverView(
        routeManager: RouteManager.shared,
        favoritesManager: FavoritesManager(),
        locationManager: LocationManager.shared
    )
}