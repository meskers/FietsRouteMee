//
//  SearchView.swift
//  FietsRouteMee
//
//  Volledig herbouwd - 200% werkend volgens Apple 2025 richtlijnen
//

import SwiftUI
import MapKit

struct SearchView: View {
    @ObservedObject var routeManager: RouteManager
    @ObservedObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss
    var onLocationSelected: ((CLLocationCoordinate2D?, CLLocationCoordinate2D?) -> Void)? = nil
    
    @State private var startSearchText = ""
    @State private var endSearchText = ""
    @State private var startSearchResults: [MKMapItem] = []
    @State private var endSearchResults: [MKMapItem] = []
    @State private var isSearchingStart = false
    @State private var isSearchingEnd = false
    @State private var selectedStartLocation: CLLocationCoordinate2D?
    @State private var selectedEndLocation: CLLocationCoordinate2D?
    @State private var startLocationName = ""
    @State private var endLocationName = ""
    @State private var showingStartLocationPicker = false
    @State private var showingEndLocationPicker = false
    @State private var isCalculatingRoute = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Location Selection Cards
                VStack(spacing: 16) {
                    // Start Location Card
                    LocationCard(
                        title: "Van",
                        icon: "location.circle.fill",
                        iconColor: .green,
                        locationName: startLocationName,
                        hasLocation: selectedStartLocation != nil,
                        onCurrentLocation: {
                            useCurrentLocation(for: .start)
                        },
                        onMapPick: {
                            print("🗺️ SearchView: Opening map picker for START")
                            showingStartLocationPicker = true
                        },
                        onClear: {
                            selectedStartLocation = nil
                            startLocationName = ""
                        }
                    )
                    
                    // Swap Button
                    if selectedStartLocation != nil && selectedEndLocation != nil {
                        Button {
                            swapLocations()
                        } label: {
                            Image(systemName: "arrow.up.arrow.down.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                    }
                    
                    // End Location Card
                    LocationCard(
                        title: "Naar",
                        icon: "mappin.circle.fill",
                        iconColor: .red,
                        locationName: endLocationName,
                        hasLocation: selectedEndLocation != nil,
                        onCurrentLocation: {
                            useCurrentLocation(for: .end)
                        },
                        onMapPick: {
                            print("🗺️ SearchView: Opening map picker for END")
                            showingEndLocationPicker = true
                        },
                        onClear: {
                            selectedEndLocation = nil
                            endLocationName = ""
                        }
                    )
                }
                .padding()
                .background(.ultraThinMaterial)
                
                // Content Area
                if selectedStartLocation == nil || selectedEndLocation == nil {
                    // Instructions
                    VStack(spacing: 24) {
                        Spacer()
                        
                        Image(systemName: "map.circle")
                            .font(.system(size: 72))
                            .foregroundStyle(.blue.gradient)
                        
                        VStack(spacing: 8) {
                            Text("Plan je Route")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(instructionText)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        
                        Spacer()
                    }
                } else {
                    // Calculate Route Button
                    VStack {
                        Spacer()
                        
                        // Route Info Preview
                        if let start = selectedStartLocation, let end = selectedEndLocation {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "arrow.left.and.right")
                                        .foregroundStyle(.secondary)
                                    Text("Geschatte afstand:")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(String(format: "%.1f km", start.distanceTo(end) / 1000))
                                        .fontWeight(.semibold)
                                }
                                .font(.subheadline)
                            }
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }
                        
                        // Calculate Button
                        Button {
                            Task {
                                await calculateRoute()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                if isCalculatingRoute {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Route berekenen...")
                                } else {
                                    Image(systemName: "bicycle.circle.fill")
                                        .font(.title3)
                                    Text("Route Berekenen")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                isCalculatingRoute ? 
                                    AnyShapeStyle(Color.gray) : 
                                    AnyShapeStyle(LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .leading, endPoint: .trailing)),
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                            .foregroundStyle(.white)
                        }
                        .disabled(isCalculatingRoute)
                        .padding()
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Snelle Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sluiten") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingStartLocationPicker) {
            LocationPickerView(
                locationType: .start,
                selectedLocation: $selectedStartLocation,
                onLocationSelected: { name in
                    startLocationName = name
                },
                otherStartLocation: nil,
                otherEndLocation: selectedEndLocation
            )
        }
        .sheet(isPresented: $showingEndLocationPicker) {
            LocationPickerView(
                locationType: .end,
                selectedLocation: $selectedEndLocation,
                onLocationSelected: { name in
                    endLocationName = name
                },
                otherStartLocation: selectedStartLocation,
                otherEndLocation: nil
            )
        }
        .onAppear {
            // Notify parent of current state
            onLocationSelected?(selectedStartLocation, selectedEndLocation)
        }
        .alert("Route Fout", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Helper Views
    
    private var instructionText: String {
        if selectedStartLocation == nil && selectedEndLocation == nil {
            return "Kies een start- en eindlocatie om je route te berekenen"
        } else if selectedStartLocation == nil {
            return "Kies een startlocatie om door te gaan"
        } else {
            return "Kies een bestemming om door te gaan"
        }
    }
    
    // MARK: - Actions
    
    private func useCurrentLocation(for type: LocationPickerType) {
        print("📍 SearchView: Using current location for \(type)")
        
        guard let userLocation = locationManager.userLocation?.coordinate else {
            errorMessage = "Kan huidige locatie niet bepalen. Controleer je locatie instellingen."
            showError = true
            print("❌ SearchView: No user location available")
            return
        }
        
        print("✅ SearchView: Got user location: \(userLocation.latitude), \(userLocation.longitude)")
        
        if type == .start {
            selectedStartLocation = userLocation
            startLocationName = "Huidige Locatie"
            print("✅ SearchView: Set start location to current location")
        } else {
            selectedEndLocation = userLocation
            endLocationName = "Huidige Locatie"
            print("✅ SearchView: Set end location to current location")
        }
        
        // Notify parent immediately
        onLocationSelected?(selectedStartLocation, selectedEndLocation)
        print("📍 SearchView: Notified parent of location change")
    }
    
    private func swapLocations() {
        let tempLocation = selectedStartLocation
        let tempName = startLocationName
        
        selectedStartLocation = selectedEndLocation
        startLocationName = endLocationName
        
        selectedEndLocation = tempLocation
        endLocationName = tempName
        
        // Notify parent of swap
        onLocationSelected?(selectedStartLocation, selectedEndLocation)
        print("🔄 SearchView: Swapped locations and notified parent")
    }
    
    private func calculateRoute() async {
        guard let start = selectedStartLocation,
              let end = selectedEndLocation else {
            errorMessage = "Selecteer zowel een start- als eindlocatie"
            showError = true
            return
        }
        
        print("🚴‍♂️ SearchView: Starting route calculation from \(start) to \(end)")
        isCalculatingRoute = true
        
        // Clear old routes
        await MainActor.run {
            routeManager.clearRoutes()
        }
        
        // Calculate new route with bike type from settings
        routeManager.calculateRoute(from: start, to: end, bikeType: nil) // Will use settingsManager.selectedBikeType
        
        // Wait for result
        var attempts = 0
        let maxAttempts = 50 // 5 seconds
        
        while attempts < maxAttempts {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            
            await MainActor.run {
                if !routeManager.routes.isEmpty {
                    print("✅ SearchView: Route calculated successfully")
                    isCalculatingRoute = false
                    dismiss()
                } else if let error = routeManager.errorMessage {
                    print("❌ SearchView: Route calculation failed: \(error)")
                    errorMessage = error
                    showError = true
                    isCalculatingRoute = false
                }
            }
            
            if !isCalculatingRoute {
                break
            }
            
            attempts += 1
        }
        
        // Timeout
        if attempts >= maxAttempts && isCalculatingRoute {
            await MainActor.run {
                if routeManager.routes.isEmpty {
                    errorMessage = "Route berekening duurde te lang. Probeer het opnieuw."
                    showError = true
                } else {
                    // Route was found
                    dismiss()
                }
                isCalculatingRoute = false
            }
        }
    }
}

// MARK: - Location Card

struct LocationCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let locationName: String
    let hasLocation: Bool
    let onCurrentLocation: () -> Void
    let onMapPick: () -> Void
    let onClear: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                if hasLocation {
                    Button {
                        onClear()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Selected Location Display (if any)
            if hasLocation {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(locationName)
                        .font(.body)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
            
            // Location Selection Buttons (ALWAYS visible!)
            HStack(spacing: 12) {
                Button {
                    onCurrentLocation()
                } label: {
                    HStack {
                        Image(systemName: "location.fill")
                        Text(hasLocation ? "Wijzig" : "Huidige Locatie")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.blue)
                }
                
                Button {
                    onMapPick()
                } label: {
                    HStack {
                        Image(systemName: "map")
                        Text(hasLocation ? "Wijzig" : "Op Kaart")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    SearchView(
        routeManager: RouteManager.shared,
        locationManager: LocationManager.shared
    )
}
