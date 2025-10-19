//
//  KnooppuntenPlannerView.swift
//  FietsRouteMee
//
//  Nederlandse Fietsknooppunten Planner
//

import SwiftUI
import MapKit

struct KnooppuntenPlannerView: View {
    @StateObject private var knooppuntenManager = KnooppuntenManager.shared
    @StateObject private var routeManager = RouteManager.shared
    @State private var searchText = ""
    @State private var showingMap = false
    @State private var selectedProvince = "Alle"
    
    let provinces = ["Alle", "Utrecht", "Noord-Holland", "Gelderland"]
    
    var filteredKnooppunten: [FietsKnooppunt] {
        var filtered = knooppuntenManager.knooppunten
        
        if selectedProvince != "Alle" {
            filtered = filtered.filter { $0.province == selectedProvince }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                String($0.number).contains(searchText)
            }
        }
        
        return filtered.sorted { $0.number < $1.number }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Selected Route
                if !knooppuntenManager.selectedKnooppunten.isEmpty {
                    selectedRouteSection
                }
                
                // Province Filter
                provinceFilterSection
                
                // Knooppunten List
                List {
                    ForEach(filteredKnooppunten) { knooppunt in
                        KnooppuntRow(knooppunt: knooppunt)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                knooppuntenManager.addKnooppunt(knooppunt.number)
                            }
                    }
                }
                .searchable(text: $searchText, prompt: "Zoek knooppunt nummer")
            }
            .navigationTitle("Fietsknooppunten")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingMap = true
                    } label: {
                        Image(systemName: "map")
                    }
                }
                
                if !knooppuntenManager.selectedKnooppunten.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Wis") {
                            knooppuntenManager.clearRoute()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingMap) {
                KnooppuntenMapView()
            }
        }
    }
    
    // MARK: - Selected Route Section
    
    private var selectedRouteSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "signpost.right.fill")
                    .foregroundColor(.green)
                Text("Geselecteerde Route")
                    .font(.headline)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(knooppuntenManager.selectedKnooppunten.enumerated()), id: \.offset) { index, number in
                        HStack(spacing: 4) {
                            Text("\(number)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.green)
                                .clipShape(Circle())
                            
                            if index < knooppuntenManager.selectedKnooppunten.count - 1 {
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            if let route = knooppuntenManager.calculatedRoute {
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Afstand")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f km", route.totalDistance / 1000))
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Tijd")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.0f min", route.estimatedDuration / 60))
                                .font(.headline)
                        }
                    }
                    
                    Button(action: convertToRoute) {
                        Label("Start Navigatie", systemImage: "location.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
            } else if knooppuntenManager.selectedKnooppunten.count >= 2 {
                Button(action: {
                    Task {
                        await knooppuntenManager.calculateKnooppuntRoute()
                    }
                }) {
                    Label("Bereken Route", systemImage: "arrow.triangle.branch")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Province Filter
    
    private var provinceFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(provinces, id: \.self) { province in
                    Button {
                        selectedProvince = province
                    } label: {
                        Text(province)
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedProvince == province ? Color.blue : Color(.systemGray5))
                            .foregroundColor(selectedProvince == province ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Actions
    
    private func convertToRoute() {
        guard let route = knooppuntenManager.calculatedRoute,
              let firstNum = route.knooppunten.first,
              let lastNum = route.knooppunten.last,
              let firstKnooppunt = knooppuntenManager.findKnooppunt(byNumber: firstNum),
              let lastKnooppunt = knooppuntenManager.findKnooppunt(byNumber: lastNum) else {
            return
        }
        
        // Get waypoints
        var waypoints: [CLLocationCoordinate2D] = []
        for i in 1..<route.knooppunten.count - 1 {
            if let knooppunt = knooppuntenManager.findKnooppunt(byNumber: route.knooppunten[i]) {
                waypoints.append(knooppunt.coordinate)
            }
        }
        
        // Calculate route using RouteManager
        routeManager.calculateRoute(
            from: firstKnooppunt.coordinate,
            to: lastKnooppunt.coordinate,
            waypoints: waypoints
        )
        
        print("🚴‍♂️ Converting knooppunt route to navigation route")
    }
}

// MARK: - Knooppunt Row

struct KnooppuntRow: View {
    let knooppunt: FietsKnooppunt
    
    var body: some View {
        HStack {
            // Knooppunt Number Badge
            Text("\(knooppunt.number)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.green)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(knooppunt.displayName)
                    .font(.headline)
                
                Text(knooppunt.province)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !knooppunt.connections.isEmpty {
                    Text("Verbindingen: \(knooppunt.connections.map { String($0) }.joined(separator: ", "))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "plus.circle.fill")
                .foregroundColor(.green)
                .font(.title2)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Knooppunten Map View

struct KnooppuntenMapView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var knooppuntenManager = KnooppuntenManager.shared
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.0907, longitude: 5.1214),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
    )
    
    var body: some View {
        NavigationStack {
            Map(position: $position) {
                ForEach(knooppuntenManager.knooppunten) { knooppunt in
                    Annotation(knooppunt.displayName, coordinate: knooppunt.coordinate) {
                        Button {
                            knooppuntenManager.addKnooppunt(knooppunt.number)
                        } label: {
                            VStack(spacing: 4) {
                                Text("\(knooppunt.number)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.green)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                                
                                if knooppuntenManager.selectedKnooppunten.contains(knooppunt.number) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()
            .navigationTitle("Knooppunten Kaart")
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

#Preview {
    KnooppuntenPlannerView()
}

