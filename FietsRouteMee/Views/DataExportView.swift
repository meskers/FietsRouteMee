//
//  DataExportView.swift
//  FietsRouteMee
//
//  Volledig werkende data export functionaliteit
//

import SwiftUI
import UniformTypeIdentifiers
import CoreLocation

struct DataExportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var routeManager = RouteManager.shared
    @StateObject private var favoritesManager = FavoritesManager()
    
    @State private var isExporting = false
    @State private var exportComplete = false
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isExporting {
                    // Exporting State
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Data exporteren...")
                            .font(.headline)
                    }
                } else if exportComplete {
                    // Success State
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(.green)
                        
                        Text("Export Voltooid!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Je data is succesvol geëxporteerd")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            if let url = exportedFileURL {
                                shareFile(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Delen")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                        }
                        .padding(.horizontal)
                    }
                } else {
                    // Initial State
                    VStack(spacing: 24) {
                        Image(systemName: "square.and.arrow.up.circle")
                            .font(.system(size: 72))
                            .foregroundStyle(.blue)
                        
                        Text("Exporteer je data")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Dit exporteert al je routes, favorieten en instellingen naar een JSON bestand.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ExportInfoRow(icon: "map", text: "\(routeManager.routes.count) routes")
                            ExportInfoRow(icon: "star.fill", text: "\(favoritesManager.favoriteRoutes.count) favorieten")
                            ExportInfoRow(icon: "gear", text: "App instellingen")
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                        
                        Button {
                            exportData()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.down.circle")
                                Text("Start Export")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 32)
            .navigationTitle("Data Exporteren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sluiten") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        
        Task {
            do {
                // Create export data structure
                let exportData: [String: Any] = [
                    "export_date": ISO8601DateFormatter().string(from: Date()),
                    "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                    "routes": routeManager.routes.map { route in
                        [
                            "id": route.id.uuidString,
                            "distance": route.distance,
                            "duration": route.duration,
                            "created_at": ISO8601DateFormatter().string(from: route.createdAt),
                            "start_lat": route.startLocation.latitude,
                            "start_lng": route.startLocation.longitude,
                            "end_lat": route.endLocation.latitude,
                            "end_lng": route.endLocation.longitude
                        ]
                    },
                    "favorites": favoritesManager.favoriteRoutes.map { $0.id.uuidString },
                    "settings": [
                        "bike_type": AppSettingsManager.shared.selectedBikeType.rawValue,
                        "avoid_highways": AppSettingsManager.shared.avoidHighways,
                        "prefer_bike_paths": AppSettingsManager.shared.preferBikePaths
                    ]
                ]
                
                // Convert to JSON
                let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
                
                // Save to file
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
                let fileName = "FietsRouteMee-Export-\(dateFormatter.string(from: Date())).json"
                let fileURL = documentsPath.appendingPathComponent(fileName)
                
                try jsonData.write(to: fileURL)
                
                print("✅ Export: Data exported to \(fileURL.path)")
                
                await MainActor.run {
                    exportedFileURL = fileURL
                    isExporting = false
                    exportComplete = true
                }
            } catch {
                print("❌ Export: Failed to export data: \(error)")
                await MainActor.run {
                    isExporting = false
                }
            }
        }
    }
    
    private func shareFile(_ url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct ExportInfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    DataExportView()
}

