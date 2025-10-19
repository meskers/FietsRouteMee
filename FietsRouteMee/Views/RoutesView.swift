//
//  RoutesView.swift
//  FietsRouteMee
//
//  Volledig opnieuw gebouwd volgens Apple 2025 UI/UX richtlijnen
//

import SwiftUI
import MapKit

struct RoutesView: View {
    @ObservedObject var routeManager: RouteManager
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var favoritesManager: FavoritesManager
    @State private var selectedFilter: RouteFilter = .all
    @State private var searchText = ""
    @State private var selectedRoute: BikeRoute?
    @State private var showingSortMenu = false
    @State private var sortOption: SortOption = .newest
    @State private var isRefreshing = false
    
    enum RouteFilter: String, CaseIterable {
        case all = "Alle"
        case favorites = "Favorieten"
        case recent = "Recent"
        
        var icon: String {
            switch self {
            case .all: return "map"
            case .favorites: return "heart.fill"
            case .recent: return "clock.fill"
            }
        }
    }
    
    enum SortOption: String, CaseIterable {
        case newest = "Nieuwste eerst"
        case oldest = "Oudste eerst"
        case distance = "Afstand"
        case duration = "Duur"
        case difficulty = "Moeilijkheid"
        
        var icon: String {
            switch self {
            case .newest, .oldest: return "calendar"
            case .distance: return "arrow.left.and.right"
            case .duration: return "clock"
            case .difficulty: return "chart.bar"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(RouteFilter.allCases, id: \.self) { filter in
                            FilterPill(
                                title: filter.rawValue,
                                icon: filter.icon,
                                isSelected: selectedFilter == filter,
                                action: { selectedFilter = filter }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                
                // Routes List
                if filteredRoutes.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(filteredRoutes) { route in
                            ModernRouteCard(
                                route: route,
                                favoritesManager: favoritesManager,
                                onTap: {
                                    selectedRoute = route
                                }
                            )
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteRoute(route)
                                } label: {
                                    Label("Verwijder", systemImage: "trash")
                                }
                                
                                Button {
                                    toggleFavorite(route)
                                } label: {
                                    Label(
                                        favoritesManager.isFavorite(route) ? "Verwijder uit favorieten" : "Voeg toe aan favorieten",
                                        systemImage: favoritesManager.isFavorite(route) ? "heart.slash" : "heart"
                                    )
                                }
                                .tint(.pink)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .searchable(text: $searchText, prompt: "Zoek routes...")
            .navigationTitle("Routes")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Load saved routes when view appears
                print("📱 RoutesView: View appeared - Loading saved routes")
                refreshRoutes()
            }
            .refreshable {
                // Pull to refresh
                await refreshRoutesAsync()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                sortOption = option
                            } label: {
                                Label(option.rawValue, systemImage: option.icon)
                            }
                        }
                    } label: {
                        Label("Sorteren", systemImage: "arrow.up.arrow.down")
                            .labelStyle(.iconOnly)
                    }
                }
            }
            .sheet(item: $selectedRoute) { route in
                RouteDetailsView(
                    route: route,
                    routeManager: routeManager,
                    locationManager: locationManager,
                    voiceManager: VoiceNavigationManager.shared
                )
            }
        }
    }
    
    // MARK: - Filtered & Sorted Routes
    
    private var filteredRoutes: [BikeRoute] {
        var routes = routeManager.routes
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .favorites:
            routes = favoritesManager.favoriteRoutes
        case .recent:
            routes = routes.sorted { $0.createdAt > $1.createdAt }.prefix(10).map { $0 }
        }
        
        // Apply search
        if !searchText.isEmpty {
            routes = routes.filter { route in
                route.formattedDistance.localizedCaseInsensitiveContains(searchText) ||
                route.formattedDuration.localizedCaseInsensitiveContains(searchText) ||
                route.difficulty.displayName.localizedCaseInsensitiveContains(searchText) ||
                route.surface.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply sort
        switch sortOption {
        case .newest:
            routes = routes.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            routes = routes.sorted { $0.createdAt < $1.createdAt }
        case .distance:
            routes = routes.sorted { $0.distance > $1.distance }
        case .duration:
            routes = routes.sorted { $0.duration > $1.duration }
        case .difficulty:
            routes = routes.sorted { $0.difficulty.rawValue > $1.difficulty.rawValue }
        }
        
        return routes
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: emptyStateIcon)
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)
            }
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(emptyStateSubtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if selectedFilter == .all && routeManager.routes.isEmpty {
                NavigationLink(destination: Text("Kaart tab")) {
                    Text("Plan je eerste route")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 32)
                }
            }
            
            Spacer()
        }
    }
    
    private var emptyStateIcon: String {
        switch selectedFilter {
        case .all: return "map"
        case .favorites: return "heart"
        case .recent: return "clock"
        }
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "Geen routes gevonden"
        }
        
        switch selectedFilter {
        case .all: return "Nog geen routes"
        case .favorites: return "Geen favorieten"
        case .recent: return "Geen recente routes"
        }
    }
    
    private var emptyStateSubtitle: String {
        if !searchText.isEmpty {
            return "Probeer een andere zoekterm"
        }
        
        switch selectedFilter {
        case .all: return "Plan je eerste route via de Kaart tab om hier te zien"
        case .favorites: return "Markeer routes als favoriet om ze hier te bewaren"
        case .recent: return "Je recent gebruikte routes verschijnen hier"
        }
    }
    
    // MARK: - Refresh Functions
    
    private func refreshRoutes() {
        Task {
            await refreshRoutesAsync()
        }
    }
    
    private func refreshRoutesAsync() async {
        isRefreshing = true
        print("🔄 RoutesView: Refreshing routes from CoreData")
        
        await routeManager.loadSavedRoutes()
        
        print("✅ RoutesView: Loaded \(routeManager.routes.count) routes")
        print("   - Filtered routes: \(filteredRoutes.count)")
        
        isRefreshing = false
    }
    
    // MARK: - Swipe Actions
    
    private func deleteRoute(_ route: BikeRoute) {
        withAnimation(.spring()) {
            routeManager.deleteRoute(route)
            print("🗑️ RoutesView: Deleted route \(route.id)")
        }
    }
    
    private func toggleFavorite(_ route: BikeRoute) {
        withAnimation(.spring()) {
            if favoritesManager.isFavorite(route) {
                favoritesManager.removeFavorite(route)
                print("💔 RoutesView: Removed from favorites")
            } else {
                favoritesManager.addFavorite(route)
                print("❤️ RoutesView: Added to favorites")
            }
        }
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ? Color.blue : Color(.systemGray5),
                in: Capsule()
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Modern Route Card

struct ModernRouteCard: View {
    let route: BikeRoute
    @ObservedObject var favoritesManager: FavoritesManager
    let onTap: () -> Void
    @State private var showingActions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
                // Map Preview
                RouteMapPreview(route: route)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                // Route Info
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fietsroute")
                                .font(.headline)
                            
                            HStack(spacing: 12) {
                                Label(route.formattedDistance, systemImage: "arrow.left.and.right")
                                Label(route.formattedDuration, systemImage: "clock")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            favoritesManager.toggleFavorite(route)
                        } label: {
                            Image(systemName: favoritesManager.isFavorite(route) ? "heart.fill" : "heart")
                                .font(.title3)
                                .foregroundStyle(favoritesManager.isFavorite(route) ? .red : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Badges
                    HStack(spacing: 8) {
                        DifficultyBadge(difficulty: route.difficulty)
                        
                        Badge(text: route.surface.displayName, color: .green)
                        
                        if !route.elevation.isEmpty {
                            Badge(
                                text: "+\(Int(route.elevation.max() ?? 0))m",
                                color: .orange,
                                icon: "mountain.2"
                            )
                        }
                        
                        Spacer()
                        
                        Text(route.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding()
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            Button {
                favoritesManager.toggleFavorite(route)
            } label: {
                Label(
                    favoritesManager.isFavorite(route) ? "Verwijder uit favorieten" : "Voeg toe aan favorieten",
                    systemImage: favoritesManager.isFavorite(route) ? "heart.slash" : "heart"
                )
            }
            
            Button {
                // Share functionality
            } label: {
                Label("Deel route", systemImage: "square.and.arrow.up")
            }
        }
    }
}

// MARK: - Route Map Preview (Real Map)

struct RouteMapPreview: View {
    let route: BikeRoute
    @State private var region: MKCoordinateRegion
    
    init(route: BikeRoute) {
        self.route = route
        // Calculate region to fit the route
        let coordinates = route.polyline
        if coordinates.isEmpty {
            self._region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041), // Amsterdam
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))
        } else {
            let minLat = coordinates.map { $0.latitude }.min() ?? 0
            let maxLat = coordinates.map { $0.latitude }.max() ?? 0
            let minLon = coordinates.map { $0.longitude }.min() ?? 0
            let maxLon = coordinates.map { $0.longitude }.max() ?? 0
            
            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            )
            
            let span = MKCoordinateSpan(
                latitudeDelta: max(maxLat - minLat, 0.01) * 1.2,
                longitudeDelta: max(maxLon - minLon, 0.01) * 1.2
            )
            
            self._region = State(initialValue: MKCoordinateRegion(center: center, span: span))
        }
    }
    
    var body: some View {
        Map(initialPosition: .region(region)) {
            // Start marker
            Annotation("Start", coordinate: route.startLocation) {
                Circle()
                    .fill(.green)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: 2)
                    )
            }
            
            // End marker
            Annotation("Eind", coordinate: route.endLocation) {
                Circle()
                    .fill(.red)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: 2)
                    )
            }
            
            // Route polyline
            MapPolyline(coordinates: route.polyline)
                .stroke(.blue, lineWidth: 4)
        }
        .mapStyle(.standard)
        .allowsHitTesting(false) // Disable interaction to prevent memory issues
    }
}

// MARK: - Badge Component

struct Badge: View {
    let text: String
    let color: Color
    var icon: String?
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

// RouteManager.removeRoute already exists, no extension needed

#Preview {
    RoutesView(
        routeManager: RouteManager.shared,
        locationManager: LocationManager.shared,
        favoritesManager: FavoritesManager()
    )
}
