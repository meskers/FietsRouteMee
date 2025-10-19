//
//  OfflineMapsManager.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 08/10/2025.
//

import Foundation
import MapKit
import CoreLocation
import Combine

class OfflineMapsManager: ObservableObject {
    @Published var downloadedMaps: [OfflineMapRegion] = []
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0
    @Published var currentDownload: OfflineMapRegion?
    
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let mapsDirectory: URL
    
    init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        mapsDirectory = documentsDirectory.appendingPathComponent("OfflineMaps")
        
        createMapsDirectoryIfNeeded()
        loadDownloadedMaps()
    }
    
    func downloadMap(for region: OfflineMapRegion) {
        guard !isDownloading else { return }
        
        isDownloading = true
        downloadProgress = 0
        currentDownload = region
        
        // Simulate download progress
        Task { @MainActor in
            for _ in 0..<50 {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                self.downloadProgress += 0.02
                
                if self.downloadProgress >= 1.0 {
                    self.completeDownload(for: region)
                    break
                }
            }
        }
    }
    
    func deleteMap(_ region: OfflineMapRegion) {
        let mapURL = mapsDirectory.appendingPathComponent(region.id.uuidString)
        
        do {
            try fileManager.removeItem(at: mapURL)
            downloadedMaps.removeAll { $0.id == region.id }
            saveDownloadedMaps()
        } catch {
            print("Failed to delete map: \(error)")
        }
    }
    
    func deleteAllDownloads() {
        // Remove all downloaded map files and reset state
        do {
            if fileManager.fileExists(atPath: mapsDirectory.path) {
                try fileManager.removeItem(at: mapsDirectory)
            }
        } catch {
            print("Failed to remove maps directory: \(error)")
        }
        
        // Recreate directory and clear metadata file
        createMapsDirectoryIfNeeded()
        downloadedMaps.removeAll()
        saveDownloadedMaps()
        
        // Remove persisted list file explicitly
        let mapsURL = documentsDirectory.appendingPathComponent("downloadedMaps.json")
        try? fileManager.removeItem(at: mapsURL)
    }
    
    func isMapDownloaded(for region: OfflineMapRegion) -> Bool {
        return downloadedMaps.contains { $0.id == region.id }
    }
    
    func getMapSize(for region: OfflineMapRegion) -> String {
        // Calculate estimated size based on region
        let area = calculateRegionArea(region.boundingBox)
        let sizeInMB = Int(area * 0.1) // Rough estimation
        return "\(sizeInMB) MB"
    }
    
    private func completeDownload(for region: OfflineMapRegion) {
        isDownloading = false
        downloadProgress = 0
        
        // Add to downloaded maps
        downloadedMaps.append(region)
        saveDownloadedMaps()
        
        // Create map file (in real app, this would be actual map data)
        let mapURL = mapsDirectory.appendingPathComponent(region.id.uuidString)
        let mapData = "Offline map data for \(region.name)".data(using: .utf8)!
        
        do {
            try mapData.write(to: mapURL)
        } catch {
            print("Failed to save map data: \(error)")
        }
        
        currentDownload = nil
    }
    
    private func createMapsDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: mapsDirectory.path) {
            try? fileManager.createDirectory(at: mapsDirectory, withIntermediateDirectories: true)
        }
    }
    
    private func loadDownloadedMaps() {
        let mapsURL = documentsDirectory.appendingPathComponent("downloadedMaps.json")
        
        guard let data = try? Data(contentsOf: mapsURL),
              let maps = try? JSONDecoder().decode([OfflineMapRegion].self, from: data) else {
            return
        }
        
        downloadedMaps = maps
    }
    
    private func saveDownloadedMaps() {
        let mapsURL = documentsDirectory.appendingPathComponent("downloadedMaps.json")
        
        if let data = try? JSONEncoder().encode(downloadedMaps) {
            try? data.write(to: mapsURL)
        }
    }
    
    private func calculateRegionArea(_ boundingBox: MKCoordinateRegion) -> Double {
        let latDelta = boundingBox.span.latitudeDelta
        let lngDelta = boundingBox.span.longitudeDelta
        return latDelta * lngDelta
    }
}

// MARK: - OfflineMapRegion
struct OfflineMapRegion: Identifiable, Codable {
    let id: UUID
    let name: String
    let boundingBox: MKCoordinateRegion
    let downloadDate: Date
    let size: Int // in MB
    
    init(name: String, boundingBox: MKCoordinateRegion, downloadDate: Date = Date(), size: Int) {
        self.id = UUID()
        self.name = name
        self.boundingBox = boundingBox
        self.downloadDate = downloadDate
        self.size = size
    }
    
    init(name: String, boundingBox: MKCoordinateRegion, size: Int) {
        self.id = UUID()
        self.name = name
        self.boundingBox = boundingBox
        self.downloadDate = Date()
        self.size = size
    }
}
