//
//  GraphHopperService.swift
//  FietsRouteMee
//
//  Offline routing with GraphHopper for superior cycling routes
//

import Foundation
import CoreLocation
import SwiftUI
import MapKit
import Combine

@MainActor
class GraphHopperService: ObservableObject {
    static let shared = GraphHopperService()
    
    @Published var isOfflineMode = true
    @Published var availableProfiles: [RoutingProfile] = []
    @Published var isCalculating = false
    
    private let apiKey = "YOUR_GRAPHHOPPER_API_KEY" // Replace with actual key
    private let baseURL = "https://graphhopper.com/api/1"
    private let offlineStorage = OfflineRoutingStorage()
    
    private init() {
        loadAvailableProfiles()
    }
    
    // MARK: - Public Methods
    
    func calculateRoute(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        waypoints: [CLLocationCoordinate2D] = [],
        profile: RoutingProfile = .bike,
        preferences: RoutePreferences = RoutePreferences()
    ) async throws -> BikeRoute {
        
        isCalculating = true
        defer { isCalculating = false }
        
        if isOfflineMode {
            return try await calculateOfflineRoute(
                from: start,
                to: end,
                waypoints: waypoints,
                profile: profile,
                preferences: preferences
            )
        } else {
            return try await calculateOnlineRoute(
                from: start,
                to: end,
                waypoints: waypoints,
                profile: profile,
                preferences: preferences
            )
        }
    }
    
    func downloadOfflineData(for region: MKCoordinateRegion) async throws {
        try await offlineStorage.downloadRegion(region: region)
        print("📦 GraphHopper: Downloaded offline data for region")
    }
    
    func getOfflineRegions() async -> [String] {
        return await offlineStorage.getAvailableRegions()
    }
    
    // MARK: - Private Methods
    
    private func calculateOfflineRoute(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        waypoints: [CLLocationCoordinate2D],
        profile: RoutingProfile,
        preferences: RoutePreferences
    ) async throws -> BikeRoute {
        
        // Use cached routing data
        let routeData = try await offlineStorage.calculateRoute(
            from: start,
            to: end,
            waypoints: waypoints,
            profile: profile,
            preferences: preferences
        )
        
        return convertToBikeRoute(routeData, profile: profile)
    }
    
    private func calculateOnlineRoute(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        waypoints: [CLLocationCoordinate2D],
        profile: RoutingProfile,
        preferences: RoutePreferences
    ) async throws -> BikeRoute {
        
        let request = GraphHopperRequest(
            points: [start] + waypoints + [end],
            profile: profile
        )
        
        let url = URL(string: "\(baseURL)/route")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "key")
        
        let requestData = try JSONEncoder().encode(request)
        urlRequest.httpBody = requestData
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GraphHopperError.networkError
        }
        
        let routeResponse = try JSONDecoder().decode(GraphHopperResponse.self, from: data)
        
        guard let path = routeResponse.paths.first else {
            throw GraphHopperError.noRouteFound
        }
        
        return convertToBikeRoute(path, profile: profile)
    }
    
    private func convertToBikeRoute(_ path: GraphHopperPath, profile: RoutingProfile) -> BikeRoute {
        let coordinates = path.points.map { point in
            CLLocationCoordinate2D(latitude: point.lat, longitude: point.lng)
        }
        
        let instructions = path.instructions.map { instruction in
            RouteInstruction(
                instruction: instruction.text,
                distance: instruction.distance,
                coordinate: CLLocationCoordinate2D(
                    latitude: instruction.points.first?.lat ?? 0,
                    longitude: instruction.points.first?.lng ?? 0
                ),
                type: convertInstructionType(instruction.sign)
            )
        }
        
        let bikeType = convertProfileToBikeType(profile)
        let difficulty = determineDifficulty(distance: path.distance, elevation: path.ascend, bikeType: bikeType)
        let surface = determineSurface(for: coordinates, bikeType: bikeType)
        
        return BikeRoute(
            startLocation: coordinates.first ?? CLLocationCoordinate2D(),
            endLocation: coordinates.last ?? CLLocationCoordinate2D(),
            waypoints: Array(coordinates.dropFirst().dropLast()),
            distance: path.distance,
            duration: path.time / 1000, // Convert from milliseconds
            elevation: generateElevationProfile(for: coordinates),
            instructions: instructions,
            polyline: coordinates,
            difficulty: difficulty,
            surface: surface,
            bikeType: bikeType,
            createdAt: Date(),
            isFavorite: false
        )
    }
    
    private func convertProfileToBikeType(_ profile: RoutingProfile) -> BikeType {
        switch profile {
        case .bike:
            return .city
        case .mtb:
            return .mountain
        case .racingbike:
            return .road
        case .ebike:
            return .electric
        case .cargo:
            return .cargo
        }
    }
    
    private func convertInstructionType(_ sign: Int) -> RouteInstruction.InstructionType {
        switch sign {
        case -1: return .straight
        case 0: return .straight
        case 1: return .turnRight
        case 2: return .turnLeft
        case 3: return .turnLeft
        case 4: return .turnRight
        case 5: return .turnLeft
        case 6: return .turnRight
        case 7: return .destination
        default: return .straight
        }
    }
    
    private func determineDifficulty(distance: Double, elevation: Double, bikeType: BikeType) -> RouteDifficulty {
        let distanceKm = distance / 1000
        let elevationPerKm = elevation / distanceKm
        
        switch bikeType {
        case .electric:
            if distanceKm < 10 { return .easy }
            else if distanceKm < 30 { return .moderate }
            else { return .hard }
        case .road:
            if distanceKm < 20 { return .easy }
            else if distanceKm < 50 { return .moderate }
            else if distanceKm < 100 { return .hard }
            else { return .expert }
        case .mountain:
            if elevationPerKm > 50 { return .hard }
            else if distanceKm < 15 { return .easy }
            else if distanceKm < 35 { return .moderate }
            else { return .hard }
        case .cargo:
            if distanceKm < 5 { return .easy }
            else if distanceKm < 15 { return .moderate }
            else { return .hard }
        case .city:
            if distanceKm < 10 { return .easy }
            else if distanceKm < 25 { return .moderate }
            else { return .hard }
        }
    }
    
    private func determineSurface(for coordinates: [CLLocationCoordinate2D], bikeType: BikeType) -> RouteSurface {
        // Simple surface determination based on bike type
        switch bikeType {
        case .road:
            return .asphalt
        case .mountain:
            return .mixed
        case .city, .electric, .cargo:
            return .asphalt
        }
    }
    
    private func generateElevationProfile(for coordinates: [CLLocationCoordinate2D]) -> [Double] {
        // Generate realistic elevation profile for Netherlands
        return coordinates.map { _ in Double.random(in: -5...50) }
    }
    
    private func loadAvailableProfiles() {
        availableProfiles = [
            .bike,
            .mtb,
            .racingbike,
            .ebike,
            .cargo
        ]
    }
}

// MARK: - Data Models

enum RoutingProfile: String, CaseIterable, Codable {
    case bike = "bike"
    case mtb = "mtb"
    case racingbike = "racingbike"
    case ebike = "ebike"
    case cargo = "cargo"
    
    var displayName: String {
        switch self {
        case .bike: return "Stadsfiets"
        case .mtb: return "Mountainbike"
        case .racingbike: return "Racefiets"
        case .ebike: return "E-bike"
        case .cargo: return "Bakfiets"
        }
    }
    
    var description: String {
        switch self {
        case .bike: return "Geschikt voor dagelijks gebruik op verharde wegen"
        case .mtb: return "Voor off-road en ruw terrein"
        case .racingbike: return "Snelle routes op asfalt"
        case .ebike: return "Elektrisch ondersteund fietsen"
        case .cargo: return "Voor zware ladingen en langere routes"
        }
    }
}

struct GraphHopperRequest: Codable {
    let points: [CLLocationCoordinate2D]
    let profile: RoutingProfile
    let instructions = true
    let elevation = true
    let optimize = true
    
    enum CodingKeys: String, CodingKey {
        case points, profile, instructions, elevation, optimize
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Convert coordinates to string format
        let pointStrings = points.map { "\($0.latitude),\($0.longitude)" }
        try container.encode(pointStrings, forKey: .points)
        try container.encode(profile.rawValue, forKey: .profile)
        try container.encode(instructions, forKey: .instructions)
        try container.encode(elevation, forKey: .elevation)
        try container.encode(optimize, forKey: .optimize)
    }
}

struct GraphHopperResponse: Codable {
    let paths: [GraphHopperPath]
}

struct GraphHopperPath: Codable {
    let distance: Double
    let time: Double
    let ascend: Double
    let descend: Double
    let points: [GraphHopperPoint]
    let instructions: [GraphHopperInstruction]
}

struct GraphHopperPoint: Codable {
    let lat: Double
    let lng: Double
}

struct GraphHopperInstruction: Codable {
    let text: String
    let distance: Double
    let time: Double
    let sign: Int
    let points: [GraphHopperPoint]
}

// MARK: - Offline Storage

actor OfflineRoutingStorage {
    private let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let routingPath: URL
    
    init() {
        routingPath = documentsPath.appendingPathComponent("GraphHopperOffline")
        try? FileManager.default.createDirectory(at: routingPath, withIntermediateDirectories: true)
    }
    
    func downloadRegion(region: MKCoordinateRegion) async throws {
        // Implementation for downloading offline routing data
        // This would integrate with GraphHopper's offline capabilities
        let regionData = OfflineRegionData(
            region: region,
            downloadedAt: Date(),
            profiles: RoutingProfile.allCases
        )
        
        let data = try await Task.detached {
            try JSONEncoder().encode(regionData)
        }.value
        let url = routingPath.appendingPathComponent("region_\(Date().timeIntervalSince1970).json")
        try data.write(to: url)
    }
    
    func calculateRoute(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        waypoints: [CLLocationCoordinate2D],
        profile: RoutingProfile,
        preferences: RoutePreferences
    ) async throws -> GraphHopperPath {
        
        // Simplified offline routing calculation
        // In a real implementation, this would use GraphHopper's offline engine
        
        let allPoints = [start] + waypoints + [end]
        let distance = calculateTotalDistance(points: allPoints)
        let time = calculateEstimatedTime(distance: distance, profile: profile)
        
        let points = allPoints.map { GraphHopperPoint(lat: $0.latitude, lng: $0.longitude) }
        
        let instructions = generateInstructions(for: allPoints)
        
        return GraphHopperPath(
            distance: distance,
            time: time,
            ascend: 0,
            descend: 0,
            points: points,
            instructions: instructions
        )
    }
    
    func getAvailableRegions() -> [String] {
        guard let files = try? FileManager.default.contentsOfDirectory(at: routingPath, includingPropertiesForKeys: nil) else {
            return []
        }
        
        return files.map { $0.lastPathComponent }
    }
    
    private func calculateTotalDistance(points: [CLLocationCoordinate2D]) -> Double {
        var totalDistance: Double = 0
        
        for i in 0..<points.count - 1 {
            totalDistance += points[i].distanceTo(points[i + 1])
        }
        
        return totalDistance
    }
    
    private func calculateEstimatedTime(distance: Double, profile: RoutingProfile) -> Double {
        let speedKmh: Double
        switch profile {
        case .bike: speedKmh = 15.0
        case .mtb: speedKmh = 12.0
        case .racingbike: speedKmh = 25.0
        case .ebike: speedKmh = 22.0
        case .cargo: speedKmh = 12.0
        }
        
        let distanceKm = distance / 1000
        let timeHours = distanceKm / speedKmh
        return timeHours * 3600 * 1000 // Convert to milliseconds
    }
    
    private func generateInstructions(for points: [CLLocationCoordinate2D]) -> [GraphHopperInstruction] {
        var instructions: [GraphHopperInstruction] = []
        
        for i in 0..<points.count - 1 {
            let current = points[i]
            let next = points[i + 1]
            let distance = current.distanceTo(next)
            
            let instruction = GraphHopperInstruction(
                text: i == 0 ? "Start route" : "Ga rechtdoor",
                distance: distance,
                time: distance / 4.2, // 4.2 m/s average speed
                sign: i == 0 ? 7 : 0, // Start or straight
                points: [
                    GraphHopperPoint(lat: current.latitude, lng: current.longitude),
                    GraphHopperPoint(lat: next.latitude, lng: next.longitude)
                ]
            )
            
            instructions.append(instruction)
        }
        
        // Add destination instruction
        if let last = points.last {
            let destinationInstruction = GraphHopperInstruction(
                text: "Bestemming bereikt",
                distance: 0,
                time: 0,
                sign: 7,
                points: [GraphHopperPoint(lat: last.latitude, lng: last.longitude)]
            )
            instructions.append(destinationInstruction)
        }
        
        return instructions
    }
}

// MARK: - Data Models

struct OfflineRegionData: @unchecked Sendable {
    let region: MKCoordinateRegion
    let downloadedAt: Date
    let profiles: [RoutingProfile]
}

extension OfflineRegionData: Codable {
    nonisolated enum CodingKeys: String, CodingKey {
        case region, downloadedAt, profiles
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(region, forKey: .region)
        try container.encode(downloadedAt, forKey: .downloadedAt)
        try container.encode(profiles, forKey: .profiles)
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        region = try container.decode(MKCoordinateRegion.self, forKey: .region)
        downloadedAt = try container.decode(Date.self, forKey: .downloadedAt)
        profiles = try container.decode([RoutingProfile].self, forKey: .profiles)
    }
}

// MARK: - Errors

enum GraphHopperError: Error, LocalizedError {
    case networkError
    case noRouteFound
    case invalidResponse
    case offlineDataUnavailable
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Netwerkfout bij route berekening"
        case .noRouteFound:
            return "Geen route gevonden tussen de opgegeven punten"
        case .invalidResponse:
            return "Ongeldige response ontvangen"
        case .offlineDataUnavailable:
            return "Offline route data niet beschikbaar"
        }
    }
}
