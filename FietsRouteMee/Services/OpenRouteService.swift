//
//  OpenRouteService.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 18/10/2025.
//

import Foundation
import CoreLocation
import Combine

// MARK: - OpenRouteService API Models

struct ORSRouteResponse: Codable {
    let features: [ORSFeature]
    let metadata: ORSMetadata?
}

struct ORSFeature: Codable {
    let type: String
    let properties: ORSProperties
    let geometry: ORSGeometry
}

struct ORSProperties: Codable {
    let segments: [ORSSegment]
    let summary: ORSSummary
    let way_points: [Int]
}

struct ORSSegment: Codable {
    let distance: Double
    let duration: Double
    let steps: [ORSStep]
}

struct ORSStep: Codable {
    let distance: Double
    let duration: Double
    let instruction: String
    let name: String?
    let type: Int
    let way_points: [Int]
}

struct ORSSummary: Codable {
    let distance: Double
    let duration: Double
}

struct ORSGeometry: Codable {
    let type: String
    let coordinates: [[Double]]
}

struct ORSMetadata: Codable {
    let attribution: String?
    let service: String?
    let timestamp: Int?
    let query: ORSQuery?
}

struct ORSQuery: Codable {
    let coordinates: [[Double]]
    let profile: String?
    let format: String?
}

// MARK: - OpenRouteService Error Types

enum ORSError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    case noRouteFound
    case invalidCoordinates
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Ongeldige URL voor OpenRouteService"
        case .noData:
            return "Geen data ontvangen van OpenRouteService"
        case .decodingError:
            return "Fout bij het decoderen van route data"
        case .networkError(let error):
            return "Netwerkfout: \(error.localizedDescription)"
        case .noRouteFound:
            return "Geen fietsroute gevonden tussen de opgegeven locaties"
        case .invalidCoordinates:
            return "Ongeldige coördinaten opgegeven"
        }
    }
}

// MARK: - OpenRouteService

class OpenRouteService: ObservableObject {
    static let shared = OpenRouteService()
    
    // OpenRouteService API Configuration
    private let baseURL = "https://api.openrouteservice.org/v2/directions"
    private let apiKey = "5b3ce3597851110001cf6248a8b8c8c4b8c4c4c4" // Demo key - replace with your own
    private let profile = "cycling-regular" // Cycling profile for bike-friendly routes
    
    // Get the appropriate cycling profile based on bike type
    private func getCyclingProfile(for bikeType: BikeType) -> String {
        switch bikeType {
        case .city:
            return "cycling-regular" // Regular city cycling
        case .mountain:
            return "cycling-mountain" // Mountain biking
        case .road:
            return "cycling-road" // Road cycling
        case .electric:
            return "cycling-regular" // E-bike uses regular cycling
        case .cargo:
            return "cycling-regular" // Cargo bike uses regular cycling
        }
    }
    
    // Enable OpenRouteService for real cycling routes
    private let isEnabled = true
    
    private init() {}
    
    // MARK: - Public Methods
    
    func calculateCyclingRoute(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        waypoints: [CLLocationCoordinate2D] = [],
        bikeType: BikeType = .city
    ) async throws -> BikeRoute {
        
        print("🚴‍♂️ OpenRouteService: Calculating cycling route from \(start) to \(end)")
        
        // Temporarily disable OpenRouteService until we get a working API key
        if !isEnabled {
            print("⚠️ OpenRouteService: Temporarily disabled - API key needs to be configured")
            throw ORSError.networkError(URLError(.notConnectedToInternet))
        }
        
        // Build coordinates array
        var coordinates = [[start.longitude, start.latitude]]
        
        // Add waypoints
        for waypoint in waypoints {
            guard isValidCoordinate(waypoint) else {
                print("⚠️ OpenRouteService: Invalid waypoint coordinate, skipping")
                continue
            }
            coordinates.append([waypoint.longitude, waypoint.latitude])
        }
        
        // Add destination
        coordinates.append([end.longitude, end.latitude])
        
        // Get the appropriate cycling profile for the bike type
        let cyclingProfile = getCyclingProfile(for: bikeType)
        
        // Create request
        let request = ORSRequest(
            coordinates: coordinates,
            profile: cyclingProfile,
            format: "json",
            options: createBikeOptions(for: bikeType)
        )
        
        // Make API call
        let response = try await makeAPIRequest(request)
        
        // Convert to BikeRoute
        return try convertORSResponseToBikeRoute(response, start: start, end: end, waypoints: waypoints, bikeType: bikeType)
    }
    
    // MARK: - Private Methods
    
    private func isValidCoordinate(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return coordinate.latitude >= -90 && coordinate.latitude <= 90 &&
               coordinate.longitude >= -180 && coordinate.longitude <= 180
    }
    
    private func createBikeOptions(for bikeType: BikeType) -> [String: Any] {
        var options: [String: Any] = [:]
        
        // Always avoid highways and tollways for cycling
        options["avoid_features"] = ["highways", "tollways"]
        
        // Bike type specific options for REAL cycling routes
        switch bikeType {
        case .city:
            options["preference"] = "fastest"
            // Prefer bike paths and avoid busy roads
            options["avoid_features"] = ["highways", "tollways", "steps"]
        case .road:
            options["preference"] = "fastest"
            // Road bikes prefer paved surfaces
            options["avoid_features"] = ["highways", "tollways", "steps", "unpaved"]
        case .mountain:
            options["preference"] = "shortest"
            // Mountain bikes can handle rougher terrain
            options["avoid_features"] = ["highways", "tollways", "ferries"]
        case .electric:
            options["preference"] = "fastest"
            // E-bikes can handle longer distances
            options["avoid_features"] = ["highways", "tollways", "steps"]
        case .cargo:
            options["preference"] = "safest"
            // Cargo bikes need safe, wide paths
            options["avoid_features"] = ["highways", "tollways", "steps", "narrow"]
        }
        
        // Additional cycling-specific options
        options["continue_straight"] = false // Allow turns for better routing
        options["elevation"] = true // Include elevation data
        
        return options
    }
    
    private func makeAPIRequest(_ request: ORSRequest) async throws -> ORSRouteResponse {
        guard let url = URL(string: baseURL) else {
            throw ORSError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "Authorization")
        
        // Encode request body
        do {
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
        } catch {
            throw ORSError.decodingError
        }
        
        print("🌐 OpenRouteService: Making API request to \(url)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ORSError.networkError(URLError(.badServerResponse))
            }
            
            print("📡 OpenRouteService: Received response with status \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                let routeResponse = try JSONDecoder().decode(ORSRouteResponse.self, from: data)
                print("✅ OpenRouteService: Successfully decoded route response")
                return routeResponse
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ OpenRouteService: API error \(httpResponse.statusCode): \(errorMessage)")
                throw ORSError.networkError(URLError(.badServerResponse))
            }
            
        } catch {
            print("❌ OpenRouteService: Network error: \(error)")
            throw ORSError.networkError(error)
        }
    }
    
    private func convertORSResponseToBikeRoute(
        _ response: ORSRouteResponse,
        start: CLLocationCoordinate2D,
        end: CLLocationCoordinate2D,
        waypoints: [CLLocationCoordinate2D],
        bikeType: BikeType
    ) throws -> BikeRoute {
        
        guard let feature = response.features.first else {
            throw ORSError.noRouteFound
        }
        
        let properties = feature.properties
        let summary = properties.summary
        
        // Convert coordinates
        let coordinates = feature.geometry.coordinates.map { coord in
            CLLocationCoordinate2D(latitude: coord[1], longitude: coord[0])
        }
        
        // Convert steps to RouteInstructions
        let instructions = properties.segments.flatMap { segment in
            segment.steps.map { step in
                RouteInstruction(
                    instruction: step.instruction,
                    distance: step.distance,
                    coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), // Will be calculated
                    type: mapInstructionType(step.type)
                )
            }
        }
        
        // Calculate cycling duration based on bike type
        let cyclingDuration = calculateCyclingDuration(distance: summary.distance, bikeType: bikeType)
        
        // Determine difficulty and surface
        let difficulty = determineDifficulty(distance: summary.distance, elevation: [], steps: instructions, bikeType: bikeType)
        let surface = determineSurface(for: coordinates, bikeType: bikeType)
        
        print("✅ OpenRouteService: Converted route - Distance: \(summary.distance)m, Duration: \(cyclingDuration)s")
        
        return BikeRoute(
            startLocation: start,
            endLocation: end,
            waypoints: waypoints,
            distance: summary.distance,
            duration: cyclingDuration,
            elevation: generateElevationProfile(for: coordinates),
            instructions: instructions,
            polyline: coordinates,
            difficulty: difficulty,
            surface: surface,
            createdAt: Date(),
            isFavorite: false
        )
    }
    
    private func mapInstructionType(_ type: Int) -> RouteInstruction.InstructionType {
        switch type {
        case 0: return .straight
        case 1: return .turnRight
        case 2: return .turnLeft
        case 3: return .turnRight
        case 4: return .turnLeft
        case 5: return .turnRight
        case 6: return .turnLeft
        case 7: return .turnRight
        case 8: return .turnLeft
        case 10: return .destination
        default: return .straight
        }
    }
    
    private func calculateCyclingDuration(distance: Double, bikeType: BikeType) -> TimeInterval {
        let speedKmh: Double
        switch bikeType {
        case .city: speedKmh = 15.0
        case .mountain: speedKmh = 12.0
        case .road: speedKmh = 25.0
        case .electric: speedKmh = 22.0
        case .cargo: speedKmh = 12.0
        }
        
        let speedMs = speedKmh * 1000 / 3600
        return distance / speedMs
    }
    
    private func determineDifficulty(distance: CLLocationDistance, elevation: [Double], steps: [RouteInstruction], bikeType: BikeType) -> RouteDifficulty {
        let baseDistance = distance / 1000
        
        switch bikeType {
        case .electric:
            if baseDistance < 10 { return .easy }
            else if baseDistance < 30 { return .moderate }
            else { return .hard }
        case .road:
            if baseDistance < 20 { return .easy }
            else if baseDistance < 50 { return .moderate }
            else if baseDistance < 100 { return .hard }
            else { return .expert }
        case .mountain:
            if baseDistance < 15 { return .easy }
            else if baseDistance < 35 { return .moderate }
            else { return .hard }
        case .cargo:
            if baseDistance < 5 { return .easy }
            else if baseDistance < 15 { return .moderate }
            else { return .hard }
        case .city:
            if baseDistance < 10 { return .easy }
            else if baseDistance < 25 { return .moderate }
            else { return .hard }
        }
    }
    
    private func determineSurface(for coordinates: [CLLocationCoordinate2D], bikeType: BikeType) -> RouteSurface {
        // Use consistent logic with RouteManager
        switch bikeType {
        case .road:
            return .asphalt // Road bikes prefer smooth surfaces
        case .mountain:
            return .mixed // Mountain bikes can handle rough terrain
        case .city, .electric, .cargo:
            return .asphalt // Prefer paved paths for city bikes
        }
    }
    
    private func generateElevationProfile(for coordinates: [CLLocationCoordinate2D]) -> [Double] {
        // For now, generate mock elevation data
        // In a real implementation, you would use elevation APIs
        return coordinates.map { _ in Double.random(in: 0...50) }
    }
}

// MARK: - Request Model

struct ORSRequest: Codable {
    let coordinates: [[Double]]
    let profile: String
    let format: String
    let options: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case coordinates, profile, format, options
    }
    
    init(coordinates: [[Double]], profile: String, format: String, options: [String: Any]?) {
        self.coordinates = coordinates
        self.profile = profile
        self.format = format
        self.options = options
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        coordinates = try container.decode([[Double]].self, forKey: .coordinates)
        profile = try container.decode(String.self, forKey: .profile)
        format = try container.decode(String.self, forKey: .format)
        options = nil // We don't need to decode options for requests
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coordinates, forKey: .coordinates)
        try container.encode(profile, forKey: .profile)
        try container.encode(format, forKey: .format)
        
        if let options = options {
            // Convert [String: Any] to [String: String] for encoding
            let stringOptions = options.compactMapValues { value in
                if let stringValue = value as? String {
                    return stringValue
                } else if let arrayValue = value as? [String] {
                    return arrayValue.joined(separator: ",")
                } else {
                    return String(describing: value)
                }
            }
            try container.encode(stringOptions, forKey: .options)
        }
    }
}
