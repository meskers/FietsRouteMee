//
//  BikeRoute.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 08/10/2025.
//

import Foundation
import MapKit
import CoreLocation
import SwiftUI

enum BikeType: String, CaseIterable, Codable {
    case city = "city"
    case mountain = "mountain"
    case road = "road"
    case electric = "electric"
    case cargo = "cargo"
    
    var displayName: String {
        switch self {
        case .city: return "Stadsfiets"
        case .mountain: return "Mountainbike"
        case .road: return "Racefiets"
        case .electric: return "E-bike"
        case .cargo: return "Bakfiets"
        }
    }
    
    var icon: String {
        switch self {
        case .city: return "bicycle"
        case .mountain: return "bicycle"
        case .road: return "bicycle"
        case .electric: return "bolt.circle"
        case .cargo: return "truck.box"
        }
    }
}

enum RouteDifficulty: String, CaseIterable, Codable {
    case easy = "easy"
    case moderate = "moderate"
    case hard = "hard"
    case expert = "expert"
    
    var displayName: String {
        switch self {
        case .easy: return "Makkelijk"
        case .moderate: return "Gemiddeld"
        case .hard: return "Moeilijk"
        case .expert: return "Expert"
        }
    }
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .moderate: return .yellow
        case .hard: return .orange
        case .expert: return .red
        }
    }
}

enum RouteSurface: String, CaseIterable, Codable {
    case asphalt = "asphalt"
    case gravel = "gravel"
    case dirt = "dirt"
    case mixed = "mixed"
    
    var displayName: String {
        switch self {
        case .asphalt: return "Asfalt"
        case .gravel: return "Grind"
        case .dirt: return "Zandpad"
        case .mixed: return "Gemengd"
        }
    }
}

struct RouteInstruction: Identifiable, Codable {
    let id: UUID
    let instruction: String
    let distance: Double
    let coordinate: CLLocationCoordinate2D
    let type: InstructionType
    
    nonisolated init(instruction: String, distance: Double, coordinate: CLLocationCoordinate2D, type: InstructionType) {
        self.id = UUID()
        self.instruction = instruction
        self.distance = distance
        self.coordinate = coordinate
        self.type = type
    }
    
    enum InstructionType: String, CaseIterable, Codable {
        case start = "start"
        case turnLeft = "turnLeft"
        case turnRight = "turnRight"
        case straight = "straight"
        case destination = "destination"
        case roundabout = "roundabout"
        case uTurn = "uTurn"
    }
}

struct RoutePreferences: Codable {
    var avoidHighways: Bool = true
    var avoidTunnels: Bool = false
    var preferBikePaths: Bool = true
    var preferNature: Bool = false
    var maxDistance: Double = 50.0 // km
    var maxElevation: Double = 200.0 // meters
}

struct RouteRequest: Codable {
    let id: UUID
    let start: CLLocationCoordinate2D
    let end: CLLocationCoordinate2D
    let waypoints: [CLLocationCoordinate2D]
    let bikeType: BikeType
    let preferences: RoutePreferences
    let timestamp: Date
    
    init(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, waypoints: [CLLocationCoordinate2D] = [], bikeType: BikeType = .city, preferences: RoutePreferences = RoutePreferences()) {
        self.id = UUID()
        self.start = start
        self.end = end
        self.waypoints = waypoints
        self.bikeType = bikeType
        self.preferences = preferences
        self.timestamp = Date()
    }
}

struct BikeRoute: Identifiable, Codable {
    let id: UUID
    let startLocation: CLLocationCoordinate2D
    let endLocation: CLLocationCoordinate2D
    let waypoints: [CLLocationCoordinate2D]
    let distance: Double // in meters
    let duration: TimeInterval // in seconds
    let elevation: [Double] // elevation profile
    let instructions: [RouteInstruction]
    let polyline: [CLLocationCoordinate2D]
    let difficulty: RouteDifficulty
    let surface: RouteSurface
    let bikeType: BikeType // Store the bike type used for this route
    let createdAt: Date
    let isFavorite: Bool
    
    nonisolated init(startLocation: CLLocationCoordinate2D, endLocation: CLLocationCoordinate2D, waypoints: [CLLocationCoordinate2D] = [], distance: Double, duration: TimeInterval, elevation: [Double] = [], instructions: [RouteInstruction] = [], polyline: [CLLocationCoordinate2D] = [], difficulty: RouteDifficulty = .easy, surface: RouteSurface = .asphalt, bikeType: BikeType = .city, createdAt: Date = Date(), isFavorite: Bool = false) {
        self.id = UUID()
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.waypoints = waypoints
        self.distance = distance
        self.duration = duration
        self.elevation = elevation
        self.instructions = instructions
        self.polyline = polyline
        self.difficulty = difficulty
        self.surface = surface
        self.bikeType = bikeType
        self.createdAt = createdAt
        self.isFavorite = isFavorite
    }
    
    // Computed properties
    var formattedDistance: String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)u \(minutes)min"
        } else {
            return "\(minutes) min"
        }
    }
    
    var averageSpeed: Double {
        // Use the stored bike type to get the correct speed
        switch bikeType {
        case .city: return 15.0
        case .mountain: return 12.0
        case .road: return 25.0
        case .electric: return 22.0
        case .cargo: return 12.0
        }
    }
    
    var elevationGain: Double {
        guard !elevation.isEmpty else { return 0 }
        return elevation.max()! - elevation.min()!
    }
    
    var start: CLLocationCoordinate2D {
        return startLocation
    }
    
    var end: CLLocationCoordinate2D {
        return endLocation
    }
}

// MARK: - Codable Extensions
extension CLLocationCoordinate2D: @retroactive Codable {
    enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
}