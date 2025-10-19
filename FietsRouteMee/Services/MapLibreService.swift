//
//  MapLibreService.swift
//  FietsRouteMee
//
//  Advanced MapLibre integration for superior cycling maps
//

import Foundation
import CoreLocation
import SwiftUI
import MapKit
import Combine

@MainActor
class MapLibreService: ObservableObject {
    static let shared = MapLibreService()
    
    @Published var isOfflineMode = false
    @Published var downloadedRegions: [String] = []
    @Published var cyclingPOIs: [CyclingPOI] = []
    
    private let styleURL = Bundle.main.url(forResource: "cycling-style", withExtension: "json")
    private let offlineStorage = OfflineMapStorage()
    
    private init() {
        setupCyclingStyle()
        loadOfflineRegions()
    }
    
    // MARK: - Cycling Style Configuration
    
    private func setupCyclingStyle() {
        // Create custom cycling-optimized style
        let cyclingStyle = createCyclingStyle()
        
        // Save to bundle
        if let data = try? JSONSerialization.data(withJSONObject: cyclingStyle, options: .prettyPrinted) {
            let url = Bundle.main.bundleURL.appendingPathComponent("cycling-style.json")
            try? data.write(to: url)
        }
    }
    
    private func createCyclingStyle() -> [String: Any] {
        return [
            "version": 8,
            "name": "FietsRouteMee Cycling Style",
            "sources": [
                "openstreetmap": [
                    "type": "raster",
                    "tiles": [
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
                    ],
                    "tileSize": 256,
                    "maxzoom": 19
                ],
                "cycling-infrastructure": [
                    "type": "vector",
                    "tiles": [
                        "https://tile.thunderforest.com/cycle/{z}/{x}/{y}.png?apikey=YOUR_API_KEY"
                    ],
                    "minzoom": 0,
                    "maxzoom": 20
                ]
            ],
            "layers": [
                // Base map
                [
                    "id": "osm-base",
                    "type": "raster",
                    "source": "openstreetmap",
                    "minzoom": 0,
                    "maxzoom": 19
                ],
                // Cycleways - Highlighted in green
                [
                    "id": "cycleways",
                    "type": "line",
                    "source": "cycling-infrastructure",
                    "source-layer": "cycleway",
                    "paint": [
                        "line-color": "#00ff00",
                        "line-width": [
                            "interpolate",
                            ["linear"],
                            ["zoom"],
                            10, 2,
                            16, 6
                        ],
                        "line-opacity": 0.8
                    ],
                    "filter": ["==", "highway", "cycleway"]
                ],
                // Bike paths - Blue
                [
                    "id": "bike-paths",
                    "type": "line",
                    "source": "cycling-infrastructure",
                    "source-layer": "path",
                    "paint": [
                        "line-color": "#0066cc",
                        "line-width": [
                            "interpolate",
                            ["linear"],
                            ["zoom"],
                            10, 1.5,
                            16, 4
                        ],
                        "line-dasharray": [2, 2]
                    ],
                    "filter": ["==", "bicycle", "designated"]
                ],
                // Dutch cycling junctions (fietsknooppunten)
                [
                    "id": "cycling-junctions",
                    "type": "circle",
                    "source": "cycling-infrastructure",
                    "source-layer": "junction",
                    "paint": [
                        "circle-color": "#ff6600",
                        "circle-radius": [
                            "interpolate",
                            ["linear"],
                            ["zoom"],
                            10, 3,
                            16, 8
                        ],
                        "circle-stroke-color": "#ffffff",
                        "circle-stroke-width": 2
                    ],
                    "filter": ["==", "network", "rwn"]
                ]
            ]
        ]
    }
    
    // MARK: - Offline Maps
    
    func downloadRegion(for bounds: MKCoordinateRegion, name: String) async {
        do {
            try await offlineStorage.downloadRegion(bounds: bounds, name: name)
            downloadedRegions.append(name)
            print("🗺️ MapLibre: Downloaded region '\(name)'")
        } catch {
            print("❌ MapLibre: Failed to download region: \(error)")
        }
    }
    
    func deleteOfflineRegion(_ name: String) async {
        do {
            try await offlineStorage.deleteRegion(name: name)
            downloadedRegions.removeAll { $0 == name }
            print("🗑️ MapLibre: Deleted region '\(name)'")
        } catch {
            print("❌ MapLibre: Failed to delete region: \(error)")
        }
    }
    
    private func loadOfflineRegions() {
        downloadedRegions = offlineStorage.getAvailableRegions()
    }
    
    // MARK: - Cycling POIs
    
    func loadCyclingPOIs(near coordinate: CLLocationCoordinate2D, radius: CLLocationDistance = 5000) async {
        do {
            let pois = try await fetchCyclingPOIs(center: coordinate, radius: radius)
            cyclingPOIs = pois
            print("🚴‍♂️ MapLibre: Loaded \(pois.count) cycling POIs")
        } catch {
            print("❌ MapLibre: Failed to load cycling POIs: \(error)")
        }
    }
    
    private func fetchCyclingPOIs(center: CLLocationCoordinate2D, radius: CLLocationDistance) async throws -> [CyclingPOI] {
        // Overpass API query for cycling infrastructure
        let query = """
        [out:json][timeout:25];
        (
          node["amenity"="bicycle_rental"](around:\(Int(radius)),\(center.latitude),\(center.longitude));
          node["amenity"="bicycle_repair_station"](around:\(Int(radius)),\(center.latitude),\(center.longitude));
          node["shop"="bicycle"](around:\(Int(radius)),\(center.latitude),\(center.longitude));
          node["leisure"="park"](around:\(Int(radius)),\(center.latitude),\(center.longitude));
        );
        out geom;
        """
        
        let url = URL(string: "https://overpass-api.de/api/interpreter")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = query.data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let elements = response?["elements"] as? [[String: Any]] else {
            return []
        }
        
        return elements.compactMap { CyclingPOI.fromOverpassElement($0) }
    }
}

// MARK: - Supporting Types

struct CyclingPOI: Identifiable, Codable {
    let id: UUID
    let name: String
    let type: POIType
    let coordinate: CLLocationCoordinate2D
    let tags: [String: String]
    
    enum POIType: String, Codable, CaseIterable {
        case bicycleRental = "bicycle_rental"
        case bicycleRepair = "bicycle_repair_station"
        case bicycleShop = "bicycle_shop"
        case park = "park"
        case cyclingJunction = "cycling_junction"
        
        var displayName: String {
            switch self {
            case .bicycleRental: return "Fietsverhuur"
            case .bicycleRepair: return "Fietsreparatie"
            case .bicycleShop: return "Fietsenwinkel"
            case .park: return "Park"
            case .cyclingJunction: return "Fietsknooppunt"
            }
        }
        
        var icon: String {
            switch self {
            case .bicycleRental: return "bicycle"
            case .bicycleRepair: return "wrench.and.screwdriver"
            case .bicycleShop: return "storefront"
            case .park: return "tree"
            case .cyclingJunction: return "circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .bicycleRental: return .blue
            case .bicycleRepair: return .orange
            case .bicycleShop: return .green
            case .park: return .green
            case .cyclingJunction: return .red
            }
        }
    }
    
    static func fromOverpassElement(_ element: [String: Any]) -> CyclingPOI? {
        guard let tags = element["tags"] as? [String: String],
              let lat = element["lat"] as? Double,
              let lon = element["lon"] as? Double else {
            return nil
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let name = tags["name"] ?? tags["brand"] ?? "Onbekend"
        
        // Determine POI type
        let type: POIType
        if tags["amenity"] == "bicycle_rental" {
            type = .bicycleRental
        } else if tags["amenity"] == "bicycle_repair_station" {
            type = .bicycleRepair
        } else if tags["shop"] == "bicycle" {
            type = .bicycleShop
        } else if tags["leisure"] == "park" {
            type = .park
        } else {
            return nil
        }
        
        return CyclingPOI(
            id: UUID(),
            name: name,
            type: type,
            coordinate: coordinate,
            tags: tags
        )
    }
}

// MARK: - Offline Storage

class OfflineMapStorage {
    private let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let regionsPath: URL
    
    init() {
        regionsPath = documentsPath.appendingPathComponent("MapLibreRegions")
        try? FileManager.default.createDirectory(at: regionsPath, withIntermediateDirectories: true)
    }
    
    func downloadRegion(bounds: MKCoordinateRegion, name: String) async throws {
        // Implementation for downloading map tiles
        // This would integrate with MapLibre's offline pack system
        let regionData = RegionData(name: name, bounds: bounds, downloadedAt: Date())
        let data = try JSONEncoder().encode(regionData)
        let url = regionsPath.appendingPathComponent("\(name).json")
        try data.write(to: url)
    }
    
    func deleteRegion(name: String) async throws {
        let url = regionsPath.appendingPathComponent("\(name).json")
        try FileManager.default.removeItem(at: url)
    }
    
    func getAvailableRegions() -> [String] {
        guard let files = try? FileManager.default.contentsOfDirectory(at: regionsPath, includingPropertiesForKeys: nil) else {
            return []
        }
        
        return files.compactMap { url in
            url.deletingPathExtension().lastPathComponent
        }
    }
}

struct RegionData: Codable {
    let name: String
    let bounds: MKCoordinateRegion
    let downloadedAt: Date
}

// MARK: - MKCoordinateRegion Codable Extension

extension MKCoordinateSpan: @retroactive Codable {
    enum CodingKeys: String, CodingKey {
        case latitudeDelta, longitudeDelta
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitudeDelta, forKey: .latitudeDelta)
        try container.encode(longitudeDelta, forKey: .longitudeDelta)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitudeDelta = try container.decode(Double.self, forKey: .latitudeDelta)
        let longitudeDelta = try container.decode(Double.self, forKey: .longitudeDelta)
        self.init(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
    }
}

extension MKCoordinateRegion: @retroactive Codable {
    enum CodingKeys: String, CodingKey {
        case center, span
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(center, forKey: .center)
        try container.encode(span, forKey: .span)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let center = try container.decode(CLLocationCoordinate2D.self, forKey: .center)
        let span = try container.decode(MKCoordinateSpan.self, forKey: .span)
        self.init(center: center, span: span)
    }
}
