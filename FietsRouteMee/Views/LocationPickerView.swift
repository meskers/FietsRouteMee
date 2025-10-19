//
//  LocationPickerView.swift
//  FietsRouteMee
//
//  Volledig herbouwd - 200% werkend met kaart interactie
//

import SwiftUI
import MapKit

struct LocationPickerView: View {
    let locationType: LocationPickerType
    @Binding var selectedLocation: CLLocationCoordinate2D?
    var onLocationSelected: ((String) -> Void)?
    var otherStartLocation: CLLocationCoordinate2D? = nil  // Show start marker when picking end
    var otherEndLocation: CLLocationCoordinate2D? = nil    // Show end marker when picking start
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager.shared
    
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var locationName: String = "Geselecteerde locatie"
    @State private var isLoadingName = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Interactive Map
                Map(position: $position) {
                    // Show user location
                    UserAnnotation()
                    
                    // Show OTHER START marker (when picking END)
                    if locationType == .end, let startLoc = otherStartLocation {
                        Annotation("Start", coordinate: startLoc) {
                            ZStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 40, height: 40)
                                    .shadow(radius: 4)
                                
                                Image(systemName: "bicycle")
                                    .foregroundStyle(.white)
                                    .font(.title3)
                            }
                        }
                    }
                    
                    // Show OTHER END marker (when picking START)
                    if locationType == .start, let endLoc = otherEndLocation {
                        Annotation("Bestemming", coordinate: endLoc) {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 40, height: 40)
                                    .shadow(radius: 4)
                                
                                Image(systemName: "flag.fill")
                                    .foregroundStyle(.white)
                                    .font(.title3)
                            }
                        }
                    }
                    
                    // Show CURRENT selected marker (what we're picking now)
                    if let coordinate = selectedCoordinate {
                        Annotation("", coordinate: coordinate) {
                            ZStack {
                                Circle()
                                    .fill(locationType == .start ? Color.green : Color.red)
                                    .frame(width: 40, height: 40)
                                    .shadow(radius: 4)
                                
                                Image(systemName: locationType == .start ? "bicycle" : "flag.fill")
                                    .foregroundStyle(.white)
                                    .font(.title3)
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .including([.restaurant, .cafe, .hotel])))
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                .onMapCameraChange(frequency: .onEnd) { context in
                    // Update selected coordinate when map moves
                    selectedCoordinate = context.region.center
                    fetchLocationName(for: context.region.center)
                    print("📍 LocationPickerView: Map moved - selecting \(locationType == .start ? "START" : "END") at \(context.region.center.latitude), \(context.region.center.longitude)")
                }
                .ignoresSafeArea()
                
                // Center Crosshair
                Image(systemName: "scope")
                    .font(.system(size: 44))
                    .foregroundStyle(.blue)
                    .shadow(color: .black.opacity(0.3), radius: 2)
                    .allowsHitTesting(false)
                
                // Bottom Control Panel
                VStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        // Location Info
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: locationType == .start ? "location.circle.fill" : "mappin.circle.fill")
                                    .foregroundStyle(locationType == .start ? .green : .red)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(locationType == .start ? "Startlocatie" : "Bestemming")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    if isLoadingName {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Text(locationName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .lineLimit(2)
                                    }
                                }
                                
                                Spacer()
                            }
                            
                            if let coordinate = selectedCoordinate {
                                HStack {
                                    Text("Coördinaten:")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    
                                    Text("\(coordinate.latitude, specifier: "%.4f"), \(coordinate.longitude, specifier: "%.4f")")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .monospaced()
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            Button {
                                dismiss()
                            } label: {
                                Text("Annuleren")
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(.red)
                            }
                            
                            Button {
                                confirmSelection()
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Selecteren")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                                .foregroundStyle(.white)
                            }
                            .disabled(selectedCoordinate == nil)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .padding()
                }
            }
            .navigationTitle("Selecteer Locatie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onAppear {
            // Start at user location or default
            if let userLocation = locationManager.userLocation?.coordinate {
                position = .region(MKCoordinateRegion(
                    center: userLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
                selectedCoordinate = userLocation
                fetchLocationName(for: userLocation)
            } else {
                // Default to Amsterdam
                let amsterdam = CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041)
                position = .region(MKCoordinateRegion(
                    center: amsterdam,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))
                selectedCoordinate = amsterdam
                fetchLocationName(for: amsterdam)
            }
            
            print("📍 LocationPickerView: Initialized for \(locationType == .start ? "START" : "END")")
            print("   - otherStartLocation: \(otherStartLocation != nil ? "✅ Present" : "❌ Nil")")
            print("   - otherEndLocation: \(otherEndLocation != nil ? "✅ Present" : "❌ Nil")")
        }
    }
    
    // MARK: - Actions
    
    private func confirmSelection() {
        guard let coordinate = selectedCoordinate else { return }
        
        print("✅ LocationPickerView: Confirming \(locationType == .start ? "START" : "END") location:")
        print("   - Coordinate: \(coordinate.latitude), \(coordinate.longitude)")
        print("   - Name: \(locationName)")
        
        selectedLocation = coordinate
        onLocationSelected?(locationName)
        dismiss()
    }
    
    private func fetchLocationName(for coordinate: CLLocationCoordinate2D) {
        isLoadingName = true
        
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                isLoadingName = false
                
                if let placemark = placemarks?.first {
                    // Build a nice name
                    var nameComponents: [String] = []
                    
                    if let name = placemark.name, !name.isEmpty {
                        nameComponents.append(name)
                    }
                    if let thoroughfare = placemark.thoroughfare, !nameComponents.contains(thoroughfare) {
                        nameComponents.append(thoroughfare)
                    }
                    if let locality = placemark.locality {
                        nameComponents.append(locality)
                    }
                    
                    locationName = nameComponents.isEmpty ? "Geselecteerde locatie" : nameComponents.joined(separator: ", ")
                    print("📍 LocationPickerView: Got location name: \(locationName)")
                } else {
                    locationName = "Geselecteerde locatie"
                    if let error = error {
                        print("⚠️ LocationPickerView: Geocoding error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

#Preview {
    LocationPickerView(
        locationType: .start,
        selectedLocation: .constant(nil)
    )
}
