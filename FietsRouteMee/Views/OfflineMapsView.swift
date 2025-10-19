//
//  OfflineMapsView.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 08/10/2025.
//

import SwiftUI
import MapKit

struct OfflineMapsView: View {
    @StateObject private var offlineMapsManager = OfflineMapsManager()
    @StateObject private var routeCacheManager = RouteCacheManager()
    @State private var showingDownloadMap = false
    @State private var selectedRegion: OfflineMapRegion?
    
    var body: some View {
        NavigationView {
            List {
                // Cache Status Section
                Section("Cache Status") {
                    HStack {
                        Image(systemName: "externaldrive.fill")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("Route Cache")
                                .font(.headline)
                            
                            Text("\(routeCacheManager.cachedRoutes.count) routes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Leegmaken") {
                            routeCacheManager.clearCache()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 4)
                }
                
                // Downloaded Maps Section
                Section("Gedownloade Kaarten") {
                    if offlineMapsManager.downloadedMaps.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "map")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("Geen offline kaarten")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Download kaarten voor offline gebruik")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 40)
                    } else {
                        ForEach(offlineMapsManager.downloadedMaps) { map in
                            OfflineMapRow(
                                map: map,
                                isDownloaded: true,
                                onDelete: {
                                    offlineMapsManager.deleteMap(map)
                                }
                            )
                        }
                    }
                }
                
                // Available Regions Section
                Section("Beschikbare Regio's") {
                    ForEach(availableRegions) { region in
                        OfflineMapRow(
                            map: region,
                            isDownloaded: offlineMapsManager.isMapDownloaded(for: region),
                            onDownload: {
                                selectedRegion = region
                                showingDownloadMap = true
                            },
                            onDelete: {
                                offlineMapsManager.deleteMap(region)
                            }
                        )
                    }
                }
                
                // Download Progress Section
                if offlineMapsManager.isDownloading {
                    Section("Download") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Downloading \(offlineMapsManager.currentDownload?.name ?? "")")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("\(Int(offlineMapsManager.downloadProgress * 100))%")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            ProgressView(value: offlineMapsManager.downloadProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Offline Kaarten")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Instellingen") {
                        // Show settings
                    }
                }
            }
        }
        .sheet(isPresented: $showingDownloadMap) {
            if let region = selectedRegion {
                DownloadMapView(region: region, offlineMapsManager: offlineMapsManager)
            }
        }
    }
    
    private var availableRegions: [OfflineMapRegion] {
        return [
            OfflineMapRegion(
                name: "Amsterdam",
                boundingBox: MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041),
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                ),
                size: 45
            ),
            OfflineMapRegion(
                name: "Utrecht",
                boundingBox: MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 52.0907, longitude: 5.1214),
                    span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                ),
                size: 32
            ),
            OfflineMapRegion(
                name: "Den Haag",
                boundingBox: MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 52.0705, longitude: 4.3007),
                    span: MKCoordinateSpan(latitudeDelta: 0.09, longitudeDelta: 0.09)
                ),
                size: 38
            ),
            OfflineMapRegion(
                name: "Rotterdam",
                boundingBox: MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 51.9244, longitude: 4.4777),
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                ),
                size: 42
            ),
            OfflineMapRegion(
                name: "Nederland",
                boundingBox: MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 52.1326, longitude: 5.2913),
                    span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
                ),
                size: 250
            )
        ]
    }
}

struct OfflineMapRow: View {
    let map: OfflineMapRegion
    let isDownloaded: Bool
    let onDownload: (() -> Void)?
    let onDelete: (() -> Void)?
    
    init(map: OfflineMapRegion, isDownloaded: Bool, onDownload: (() -> Void)? = nil, onDelete: (() -> Void)? = nil) {
        self.map = map
        self.isDownloaded = isDownloaded
        self.onDownload = onDownload
        self.onDelete = onDelete
    }
    
    var body: some View {
        HStack {
            Image(systemName: "map")
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(map.name)
                    .font(.headline)
                
                Text("\(map.size) MB • \(formatDate(map.downloadDate))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isDownloaded {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Button("Verwijder") {
                        onDelete?()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            } else {
                Button("Download") {
                    onDownload?()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct DownloadMapView: View {
    let region: OfflineMapRegion
    @ObservedObject var offlineMapsManager: OfflineMapsManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Map Preview
                Map()
                    .mapStyle(.standard)
                    .frame(height: 200)
                    .cornerRadius(12)
                
                VStack(spacing: 16) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Download \(region.name)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Download deze kaart voor offline gebruik")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Grootte:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(region.size) MB")
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Dekking:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(region.boundingBox.span.latitudeDelta, specifier: "%.2f")° × \(region.boundingBox.span.longitudeDelta, specifier: "%.2f")°")
                                .fontWeight(.medium)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    if offlineMapsManager.isDownloading {
                        VStack(spacing: 8) {
                            ProgressView(value: offlineMapsManager.downloadProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                            
                            Text("\(Int(offlineMapsManager.downloadProgress * 100))% voltooid")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack(spacing: 16) {
                        Button("Annuleren") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        
                        Button(offlineMapsManager.isDownloading ? "Downloaden..." : "Download Starten") {
                            offlineMapsManager.downloadMap(for: region)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(offlineMapsManager.isDownloading)
                    }
                }
            }
            .padding()
            .navigationTitle("Offline Kaart")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: offlineMapsManager.isDownloading) {
                if !offlineMapsManager.isDownloading && offlineMapsManager.downloadProgress >= 1.0 {
                    dismiss()
                }
            }
        }
    }
}


#Preview {
    OfflineMapsView()
}
