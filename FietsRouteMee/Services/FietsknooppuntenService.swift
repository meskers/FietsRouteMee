//
//  FietsknooppuntenService.swift
//  FietsRouteMee
//
//  Dutch Cycling Junction Network Integration
//

import Foundation
import CoreLocation
import SwiftUI
import MapKit
import Combine

@MainActor
class FietsknooppuntenService: ObservableObject {
    static let shared = FietsknooppuntenService()
    
    @Published var knooppunten: [Fietsknooppunt] = []
    @Published var routes: [FietsknooppuntRoute] = []
    @Published var isLoading = false
    
    private let overpassAPI = "https://overpass-api.de/api/interpreter"
    private let cache = FietsknooppuntenCache()
    
    private init() {
        loadCachedData()
    }
    
    // MARK: - Public Methods
    
    func loadKnooppunten(in region: MKCoordinateRegion) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let bounds = createBounds(from: region)
            let knooppunten = try await fetchKnooppunten(bounds: bounds)
            
            // Filter and validate
            let validKnooppunten = knooppunten.filter { knooppunt in
                isValidKnooppunt(knooppunt) && isInRegion(knooppunt, region: region)
            }
            
            self.knooppunten = validKnooppunten
            await cache.saveKnooppunten(validKnooppunten)
            
            print("🚴‍♂️ Fietsknooppunten: Loaded \(validKnooppunten.count) junctions")
        } catch {
            print("❌ Fietsknooppunten: Failed to load: \(error)")
            // Fallback to cached data
            self.knooppunten = await cache.loadKnooppunten()
        }
    }
    
    func findRoute(from start: Fietsknooppunt, to end: Fietsknooppunt) async -> FietsknooppuntRoute? {
        do {
            let route = try await calculateKnooppuntRoute(from: start, to: end)
            routes.append(route)
            return route
        } catch {
            print("❌ Fietsknooppunten: Route calculation failed: \(error)")
            return nil
        }
    }
    
    func getKnooppunt(by number: String) -> Fietsknooppunt? {
        return knooppunten.first { $0.number == number }
    }
    
    func getNearbyKnooppunten(to coordinate: CLLocationCoordinate2D, radius: CLLocationDistance = 2000) -> [Fietsknooppunt] {
        return knooppunten.filter { knooppunt in
            let distance = coordinate.distanceTo(knooppunt.coordinate)
            return distance <= radius
        }.sorted { knooppunt1, knooppunten2 in
            let distance1 = coordinate.distanceTo(knooppunt1.coordinate)
            let distance2 = coordinate.distanceTo(knooppunten2.coordinate)
            return distance1 < distance2
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchKnooppunten(bounds: String) async throws -> [Fietsknooppunt] {
        let query = """
        [out:json][timeout:30];
        (
          node["network"="rwn"]["ref"~"^[0-9]+$"](\(bounds));
          node["network"="rcn"]["ref"~"^[0-9]+$"](\(bounds));
          node["network"="lcn"]["ref"~"^[0-9]+$"](\(bounds));
        );
        out geom;
        """
        
        let url = URL(string: overpassAPI)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = query.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw FietsknooppuntenError.networkError
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let elements = json?["elements"] as? [[String: Any]] else {
            throw FietsknooppuntenError.invalidData
        }
        
        return elements.compactMap { Fietsknooppunt.fromOverpassElement($0) }
    }
    
    private func createBounds(from region: MKCoordinateRegion) -> String {
        let center = region.center
        let span = region.span
        
        let south = center.latitude - span.latitudeDelta / 2
        let north = center.latitude + span.latitudeDelta / 2
        let west = center.longitude - span.longitudeDelta / 2
        let east = center.longitude + span.longitudeDelta / 2
        
        return "\(south),\(west),\(north),\(east)"
    }
    
    private func isValidKnooppunt(_ knooppunt: Fietsknooppunt) -> Bool {
        // Validate Dutch cycling junction
        return !knooppunt.number.isEmpty &&
               knooppunt.number.allSatisfy { $0.isNumber } &&
               knooppunt.coordinate.latitude >= 50.0 && knooppunt.coordinate.latitude <= 54.0 &&
               knooppunt.coordinate.longitude >= 3.0 && knooppunt.coordinate.longitude <= 8.0
    }
    
    private func isInRegion(_ knooppunt: Fietsknooppunt, region: MKCoordinateRegion) -> Bool {
        let center = region.center
        let span = region.span
        
        let latInRange = knooppunt.coordinate.latitude >= center.latitude - span.latitudeDelta/2 &&
                        knooppunt.coordinate.latitude <= center.latitude + span.latitudeDelta/2
        
        let lonInRange = knooppunt.coordinate.longitude >= center.longitude - span.longitudeDelta/2 &&
                        knooppunt.coordinate.longitude <= center.longitude + span.longitudeDelta/2
        
        return latInRange && lonInRange
    }
    
    private func calculateKnooppuntRoute(from start: Fietsknooppunt, to end: Fietsknooppunt) async throws -> FietsknooppuntRoute {
        // Simple route calculation between junctions
        // In a real implementation, this would use GraphHopper or similar
        
        let distance = start.coordinate.distanceTo(end.coordinate)
        let estimatedDuration = distance / 1000 * 4 // 4 minutes per km average
        
        return FietsknooppuntRoute(
            id: UUID(),
            start: start,
            end: end,
            waypoints: [],
            distance: distance,
            estimatedDuration: estimatedDuration,
            difficulty: .easy,
            surface: .asphalt,
            createdAt: Date()
        )
    }
    
    private func loadCachedData() {
        Task {
            knooppunten = await cache.loadKnooppunten()
        }
    }
}

// MARK: - Data Models

struct Fietsknooppunt: Identifiable, Codable, Equatable {
    let id: UUID
    let number: String
    let name: String?
    let coordinate: CLLocationCoordinate2D
    let network: NetworkType
    let tags: [String: String]
    
    static func == (lhs: Fietsknooppunt, rhs: Fietsknooppunt) -> Bool {
        return lhs.id == rhs.id &&
               lhs.number == rhs.number &&
               lhs.name == rhs.name &&
               lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude &&
               lhs.network == rhs.network
    }
    
    enum NetworkType: String, Codable, CaseIterable {
        case rwn = "rwn" // Regional cycling network
        case rcn = "rcn" // Regional cycling network (alternative)
        case lcn = "lcn" // Local cycling network
        
        var displayName: String {
            switch self {
            case .rwn: return "Regionaal Fietsnetwerk"
            case .rcn: return "Regionaal Fietsnetwerk"
            case .lcn: return "Lokaal Fietsnetwerk"
            }
        }
        
        var color: Color {
            switch self {
            case .rwn: return .red
            case .rcn: return .orange
            case .lcn: return .blue
            }
        }
    }
    
    var displayName: String {
        return name ?? "Knooppunt \(number)"
    }
    
    static func fromOverpassElement(_ element: [String: Any]) -> Fietsknooppunt? {
        guard let tags = element["tags"] as? [String: String],
              let lat = element["lat"] as? Double,
              let lon = element["lon"] as? Double,
              let ref = tags["ref"],
              let network = tags["network"] else {
            return nil
        }
        
        guard let networkType = NetworkType(rawValue: network) else {
            return nil
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let name = tags["name"]
        
        return Fietsknooppunt(
            id: UUID(),
            number: ref,
            name: name,
            coordinate: coordinate,
            network: networkType,
            tags: tags
        )
    }
}

struct FietsknooppuntRoute: Identifiable, Codable {
    let id: UUID
    let start: Fietsknooppunt
    let end: Fietsknooppunt
    let waypoints: [Fietsknooppunt]
    let distance: CLLocationDistance
    let estimatedDuration: TimeInterval
    let difficulty: RouteDifficulty
    let surface: RouteSurface
    let createdAt: Date
    
    var formattedDistance: String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
    
    var formattedDuration: String {
        let minutes = Int(estimatedDuration / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)u \(remainingMinutes)m"
        } else {
            return "\(minutes) min"
        }
    }
    
    var routeDescription: String {
        return "\(start.displayName) → \(end.displayName)"
    }
}

// MARK: - Cache

actor FietsknooppuntenCache {
    private let cacheURL: URL
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheURL = documentsPath.appendingPathComponent("fietsknooppunten.json")
    }
    
    func saveKnooppunten(_ knooppunten: [Fietsknooppunt]) async {
        do {
            let data = try JSONEncoder().encode(knooppunten)
            try data.write(to: cacheURL)
            print("💾 Fietsknooppunten: Cached \(knooppunten.count) junctions")
        } catch {
            print("❌ Fietsknooppunten: Failed to cache: \(error)")
        }
    }
    
    func loadKnooppunten() async -> [Fietsknooppunt] {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: cacheURL)
            let knooppunten = try JSONDecoder().decode([Fietsknooppunt].self, from: data)
            print("📂 Fietsknooppunten: Loaded \(knooppunten.count) cached junctions")
            return knooppunten
        } catch {
            print("❌ Fietsknooppunten: Failed to load cache: \(error)")
            return []
        }
    }
}

// MARK: - Errors

enum FietsknooppuntenError: Error, LocalizedError {
    case networkError
    case invalidData
    case noJunctionsFound
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Netwerkfout bij laden van fietsknooppunten"
        case .invalidData:
            return "Ongeldige data ontvangen"
        case .noJunctionsFound:
            return "Geen fietsknooppunten gevonden in dit gebied"
        }
    }
}
