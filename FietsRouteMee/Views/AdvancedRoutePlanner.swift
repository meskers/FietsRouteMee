//
//  AdvancedRoutePlanner.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 08/10/2025.
//

import SwiftUI
import MapKit
import CoreLocation

struct AdvancedRoutePlanner: View {
    @ObservedObject var routeManager: RouteManager
    @ObservedObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss
    var onRouteGenerated: ((BikeRoute) -> Void)? = nil
    
    @State private var bikeType: BikeType = .city
    @State private var routePreferences = RoutePreferences()
    @State private var startLocation: CLLocationCoordinate2D?
    @State private var endLocation: CLLocationCoordinate2D?
    @State private var waypoints: [CLLocationCoordinate2D] = []
    @State private var showingStartLocationPicker = false
    @State private var showingEndLocationPicker = false
    @State private var showingWaypointPicker = false
    @State private var isCalculating = false
    @State private var showingRoutePreview = false
    @State private var calculatedRoute: BikeRoute?
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Bike Type Selection
                    BikeTypeSelector(selectedType: $bikeType)
                    
                    // Location Selection
                    LocationSelectionSection(
                        startLocation: $startLocation,
                        endLocation: $endLocation,
                        waypoints: $waypoints,
                        showingStartLocationPicker: $showingStartLocationPicker,
                        showingEndLocationPicker: $showingEndLocationPicker,
                        showingWaypointPicker: $showingWaypointPicker
                    )
                    
                    // Route Preferences
                    RoutePreferencesSection(preferences: $routePreferences)
                    
                    // Calculate Button
                    CalculateButton(
                        isCalculating: isCalculating,
                        canCalculate: canCalculateRoute
                    ) {
                        calculateRoute()
                    }
                }
                .padding()
            }
            .navigationTitle("Route Plannen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuleren") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingStartLocationPicker) {
            LocationPickerView(
                locationType: .start,
                selectedLocation: $startLocation,
                onLocationSelected: { name in
                    // Handle location name if needed
                },
                otherStartLocation: nil, // No other start when picking start
                otherEndLocation: endLocation // Show end marker if already selected
            )
        }
        .sheet(isPresented: $showingEndLocationPicker) {
            LocationPickerView(
                locationType: .end,
                selectedLocation: $endLocation,
                onLocationSelected: { name in
                    // Handle location name if needed
                },
                otherStartLocation: startLocation, // Show start marker if already selected
                otherEndLocation: nil // No other end when picking end
            )
        }
        .sheet(isPresented: $showingWaypointPicker) {
            LocationPickerView(
                locationType: .waypoint,
                selectedLocation: .constant(nil), // Waypoints handled separately
                onLocationSelected: { name in
                    // Add waypoint logic here
                },
                otherStartLocation: startLocation,
                otherEndLocation: endLocation
            )
        }
        .sheet(isPresented: $showingRoutePreview) {
            if let route = calculatedRoute {
                RoutePreviewView(
                    route: route,
                    bikeType: bikeType,
                    preferences: routePreferences
                ) {
                    routeManager.routes.append(route)
                    dismiss()
                }
            }
        }
        .alert("Fout bij route berekening", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var canCalculateRoute: Bool {
        return startLocation != nil && endLocation != nil
    }
    
    
    private func calculateRoute() {
        print("🔍 AdvancedRoutePlanner: calculateRoute called")
        print("🔍 AdvancedRoutePlanner: startLocation = \(startLocation?.latitude ?? 0), \(startLocation?.longitude ?? 0)")
        print("🔍 AdvancedRoutePlanner: endLocation = \(endLocation?.latitude ?? 0), \(endLocation?.longitude ?? 0)")
        
        guard let start = startLocation, let end = endLocation else {
            print("❌ AdvancedRoutePlanner: Missing start or end location")
            errorMessage = "Selecteer zowel een start- als eindlocatie"
            showError = true
            return
        }
        
        print("🚴‍♂️ AdvancedRoutePlanner: Starting route calculation from \(start) to \(end)")
        isCalculating = true
        
        // Clear old routes first
        routeManager.clearRoutes()
        
        // Use the simplified calculateRoute method with bike type
        routeManager.calculateRoute(from: start, to: end, waypoints: waypoints, bikeType: bikeType)
        
        // Wait for route calculation with better timeout handling
        Task {
            var attempts = 0
            let maxAttempts = 30 // 3 seconds max
            
            while attempts < maxAttempts {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                
                await MainActor.run {
                    if !routeManager.routes.isEmpty {
                        print("✅ AdvancedRoutePlanner: Route found, showing preview")
                        calculatedRoute = routeManager.routes.first
                        showingRoutePreview = true
                        isCalculating = false
                        
                        // Call the callback to notify parent about the generated route
                        if let route = calculatedRoute {
                            onRouteGenerated?(route)
                        }
                        return
                    } else if let error = routeManager.errorMessage {
                        print("❌ AdvancedRoutePlanner: Route calculation failed: \(error)")
                        errorMessage = error
                        showError = true
                        isCalculating = false
                        return
                    }
                }
                
                if !isCalculating {
                    break
                }
                
                attempts += 1
            }
            
            // Timeout handling
            if isCalculating {
                await MainActor.run {
                    print("⏰ AdvancedRoutePlanner: Route calculation timeout")
                    errorMessage = "Route berekening duurt te lang. Probeer het opnieuw."
                    showError = true
                    isCalculating = false
                }
            }
        }
    }
}

struct BikeTypeSelector: View {
    @Binding var selectedType: BikeType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Type Fiets")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(BikeType.allCases, id: \.self) { type in
                    BikeTypeCard(
                        type: type,
                        isSelected: selectedType == type
                    ) {
                        selectedType = type
                    }
                }
            }
        }
    }
}

struct BikeTypeCard: View {
    let type: BikeType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .green)
                
                Text(type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected ? .green : Color(.systemGray6),
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LocationSelectionSection: View {
    @Binding var startLocation: CLLocationCoordinate2D?
    @Binding var endLocation: CLLocationCoordinate2D?
    @Binding var waypoints: [CLLocationCoordinate2D]
    @Binding var showingStartLocationPicker: Bool
    @Binding var showingEndLocationPicker: Bool
    @Binding var showingWaypointPicker: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Locaties")
                .font(.headline)
            
            VStack(spacing: 12) {
                AddressInputRow(
                    title: "Start",
                    location: $startLocation,
                    icon: "play.circle.fill",
                    color: .green
                ) {
                    showingStartLocationPicker = true
                }
                
                AddressInputRow(
                    title: "Bestemming",
                    location: $endLocation,
                    icon: "flag.circle.fill",
                    color: .red
                ) {
                    showingEndLocationPicker = true
                }
                
                // Waypoints
                if !waypoints.isEmpty {
                    ForEach(waypoints.indices, id: \.self) { index in
                        AddressInputRow(
                            title: "Tussenstop \(index + 1)",
                            location: Binding(
                                get: { waypoints[index] },
                                set: { waypoints[index] = $0 ?? CLLocationCoordinate2D(latitude: 0, longitude: 0) }
                            ),
                            icon: "mappin.circle.fill",
                            color: .blue
                        ) {
                            // Edit waypoint - could open map picker
                        }
                    }
                }
                
                Button(action: {
                    showingWaypointPicker = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                        Text("Tussenstop toevoegen")
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct AddressInputRow: View {
    let title: String
    @Binding var location: CLLocationCoordinate2D?
    let icon: String
    let color: Color
    let onMapTap: () -> Void
    
    @State private var addressText = ""
    @State private var isSearching = false
    @State private var searchResults: [MKMapItem] = []
    @State private var showingSearchResults = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Location status header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if location != nil {
                        Text("✅ Locatie geselecteerd")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    } else {
                        Text("❌ Geen locatie geselecteerd")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
                
                Button("Op Kaart") {
                    onMapTap()
                }
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            
            // Address input - Make it VERY prominent
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.blue)
                    Text("Adres Zoeken")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                HStack {
                    TextField("Bijv. Amsterdam Centraal Station", text: $addressText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            searchAddress()
                        }
                    
                    Button("Zoek") {
                        searchAddress()
                    }
                    .disabled(addressText.isEmpty || isSearching)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 8))
                }
                
                if isSearching {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Zoeken...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.blue.opacity(0.3), lineWidth: 1)
            )
            
            // Search results
            if showingSearchResults && !searchResults.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Zoek Resultaten:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    ForEach(searchResults.prefix(3), id: \.self) { item in
                        Button(action: {
                            selectSearchResult(item)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name ?? "Onbekende locatie")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    
                                    Text(item.placemark.title ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
                .background(.green.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private func searchAddress() {
        guard !addressText.isEmpty else { 
            print("🔍 AddressInputRow: Empty address text, skipping search")
            return 
        }
        
        print("🔍 AddressInputRow: Searching for '\(addressText)'")
        
        // Hide keyboard immediately when search starts
        hideKeyboard()
        
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = addressText
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041), // Amsterdam
            span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
        )
        request.resultTypes = [.pointOfInterest, .address]
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                isSearching = false
                if let error = error {
                    print("❌ AddressInputRow: Search error: \(error.localizedDescription)")
                } else if let response = response {
                    print("✅ AddressInputRow: Found \(response.mapItems.count) results")
                    searchResults = response.mapItems
                    showingSearchResults = true
                } else {
                    print("⚠️ AddressInputRow: No response and no error")
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func selectSearchResult(_ item: MKMapItem) {
        print("🔍 AddressInputRow: Selecting search result: \(item.name ?? "Unknown") at \(item.placemark.coordinate)")
        location = item.placemark.coordinate
        
        // Show full address instead of just name
        let fullAddress = item.placemark.title ?? item.name ?? "Onbekende locatie"
        addressText = fullAddress
        
        showingSearchResults = false
        searchResults = []
        
        // Hide keyboard when result is selected
        hideKeyboard()
        
        print("🔍 AddressInputRow: Location set to: \(location?.latitude ?? 0), \(location?.longitude ?? 0)")
    }
}

struct LocationRow: View {
    let title: String
    let location: CLLocationCoordinate2D?
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let location = location {
                        Text("\(location.latitude, specifier: "%.4f"), \(location.longitude, specifier: "%.4f")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Locatie selecteren")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RoutePreferencesSection: View {
    @Binding var preferences: RoutePreferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Route Voorkeuren")
                .font(.headline)
            
            VStack(spacing: 12) {
                PreferenceToggle(
                    title: "Vermijd snelwegen",
                    subtitle: "Route langs hoofdwegen",
                    isOn: $preferences.avoidHighways
                )
                
                PreferenceToggle(
                    title: "Vermijd tunnels",
                    subtitle: "Geen tunnels in route",
                    isOn: $preferences.avoidTunnels
                )
                
                PreferenceToggle(
                    title: "Voorkeur fietspaden",
                    subtitle: "Maximaal gebruik van fietspaden",
                    isOn: $preferences.preferBikePaths
                )
                
                PreferenceToggle(
                    title: "Voorkeur natuur",
                    subtitle: "Route door parken en natuur",
                    isOn: $preferences.preferNature
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Maximale afstand: \(Int(preferences.maxDistance)) km")
                        .font(.subheadline)
                    
                    Slider(value: $preferences.maxDistance, in: 5...100, step: 5)
                        .accentColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Maximale hoogte: \(Int(preferences.maxElevation))m")
                        .font(.subheadline)
                    
                    Slider(value: $preferences.maxElevation, in: 50...500, step: 25)
                        .accentColor(.green)
                }
            }
        }
    }
}

struct PreferenceToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct CalculateButton: View {
    let isCalculating: Bool
    let canCalculate: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isCalculating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "bicycle")
                }
                
                Text(isCalculating ? "Route berekenen..." : "Route Berekenen")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                canCalculate ? .green : .gray,
                in: RoundedRectangle(cornerRadius: 16)
            )
        }
        .disabled(!canCalculate || isCalculating)
        .buttonStyle(PlainButtonStyle())
    }
}

struct RoutePreviewView: View {
    let route: BikeRoute
    let bikeType: BikeType
    let preferences: RoutePreferences
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Route Summary
                    RouteSummaryCard(route: route, bikeType: bikeType)
                    
                    // Route Details
                    RouteDetailsPreview(route: route)
                    
                    // Preferences Applied
                    PreferencesAppliedCard(preferences: preferences)
                }
                .padding()
            }
            .navigationTitle("Route Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuleren") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Opslaan") {
                        onSave()
                    }
                }
            }
        }
    }
}

struct RouteSummaryCard: View {
    let route: BikeRoute
    let bikeType: BikeType
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: bikeType.icon)
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading) {
                    Text("\(bikeType.displayName) Route")
                        .font(.headline)
                    
                    Text("Geoptimaliseerd voor jouw fiets")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                StatItem(
                    icon: "ruler",
                    value: route.formattedDistance,
                    label: "Afstand"
                )
                
                StatItem(
                    icon: "clock",
                    value: route.formattedDuration,
                    label: "Tijd"
                )
                
                StatItem(
                    icon: "speedometer",
                    value: String(format: "%.1f km/h", route.averageSpeed),
                    label: "Gem. snelheid"
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct RouteDetailsPreview: View {
    let route: BikeRoute
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route Details")
                .font(.headline)
            
            HStack {
                DifficultyBadge(difficulty: route.difficulty)
                
                Text(route.surface.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            if !route.instructions.isEmpty {
                Text("\(route.instructions.count) instructies")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct PreferencesAppliedCard: View {
    let preferences: RoutePreferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Toegepaste Voorkeuren")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                if preferences.avoidHighways {
                    PreferenceAppliedRow(icon: "road.lanes", text: "Snelwegen vermeden")
                }
                
                if preferences.preferBikePaths {
                    PreferenceAppliedRow(icon: "bicycle", text: "Fietspaden gebruikt")
                }
                
                if preferences.preferNature {
                    PreferenceAppliedRow(icon: "tree", text: "Natuurroutes gekozen")
                }
                
                PreferenceAppliedRow(
                    icon: "ruler",
                    text: "Max. afstand: \(Int(preferences.maxDistance)) km"
                )
                
                PreferenceAppliedRow(
                    icon: "arrow.up.arrow.down",
                    text: "Max. hoogte: \(Int(preferences.maxElevation))m"
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct PreferenceAppliedRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
        }
    }
}


#Preview {
    AdvancedRoutePlanner(
        routeManager: RouteManager.shared,
        locationManager: LocationManager.shared
    )
}
