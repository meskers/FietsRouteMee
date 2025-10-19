//
//  Segment.swift
//  FietsRouteMee
//
//  Strava-style Segments for competitive tracking
//

import Foundation
import CoreLocation

struct Segment: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var startCoordinate: CLLocationCoordinate2D
    var endCoordinate: CLLocationCoordinate2D
    var distance: Double // meters
    var elevationGain: Double // meters
    var averageGrade: Double // percentage
    var difficulty: SegmentDifficulty
    var createdAt: Date
    var attempts: Int
    var personalBest: SegmentEffort?
    var leaderboard: [SegmentEffort]
    
    init(id: UUID = UUID(), name: String, description: String, startCoordinate: CLLocationCoordinate2D, endCoordinate: CLLocationCoordinate2D, distance: Double, elevationGain: Double, averageGrade: Double, difficulty: SegmentDifficulty = .moderate, createdAt: Date = Date(), attempts: Int = 0, personalBest: SegmentEffort? = nil, leaderboard: [SegmentEffort] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.startCoordinate = startCoordinate
        self.endCoordinate = endCoordinate
        self.distance = distance
        self.elevationGain = elevationGain
        self.averageGrade = averageGrade
        self.difficulty = difficulty
        self.createdAt = createdAt
        self.attempts = attempts
        self.personalBest = personalBest
        self.leaderboard = leaderboard
    }
    
    var formattedDistance: String {
        if distance >= 1000 {
            return String(format: "%.2f km", distance / 1000)
        } else {
            return String(format: "%.0f m", distance)
        }
    }
    
    var formattedGrade: String {
        return String(format: "%.1f%%", averageGrade)
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, name, description, startLat, startLon, endLat, endLon, distance, elevationGain, averageGrade, difficulty, createdAt, attempts, personalBest, leaderboard
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        let startLat = try container.decode(Double.self, forKey: .startLat)
        let startLon = try container.decode(Double.self, forKey: .startLon)
        startCoordinate = CLLocationCoordinate2D(latitude: startLat, longitude: startLon)
        let endLat = try container.decode(Double.self, forKey: .endLat)
        let endLon = try container.decode(Double.self, forKey: .endLon)
        endCoordinate = CLLocationCoordinate2D(latitude: endLat, longitude: endLon)
        distance = try container.decode(Double.self, forKey: .distance)
        elevationGain = try container.decode(Double.self, forKey: .elevationGain)
        averageGrade = try container.decode(Double.self, forKey: .averageGrade)
        difficulty = try container.decode(SegmentDifficulty.self, forKey: .difficulty)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        attempts = try container.decode(Int.self, forKey: .attempts)
        personalBest = try container.decodeIfPresent(SegmentEffort.self, forKey: .personalBest)
        leaderboard = try container.decode([SegmentEffort].self, forKey: .leaderboard)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(startCoordinate.latitude, forKey: .startLat)
        try container.encode(startCoordinate.longitude, forKey: .startLon)
        try container.encode(endCoordinate.latitude, forKey: .endLat)
        try container.encode(endCoordinate.longitude, forKey: .endLon)
        try container.encode(distance, forKey: .distance)
        try container.encode(elevationGain, forKey: .elevationGain)
        try container.encode(averageGrade, forKey: .averageGrade)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(attempts, forKey: .attempts)
        try container.encodeIfPresent(personalBest, forKey: .personalBest)
        try container.encode(leaderboard, forKey: .leaderboard)
    }
}

enum SegmentDifficulty: String, Codable, CaseIterable {
    case easy = "Makkelijk"
    case moderate = "Gemiddeld"
    case hard = "Zwaar"
    case expert = "Expert"
    
    var displayName: String {
        return rawValue
    }
    
    var color: String {
        switch self {
        case .easy: return "#34C759"
        case .moderate: return "#FF9500"
        case .hard: return "#FF3B30"
        case .expert: return "#AF52DE"
        }
    }
}

struct SegmentEffort: Identifiable, Codable {
    let id: UUID
    let segmentID: UUID
    let athleteName: String
    let duration: TimeInterval // seconds
    let date: Date
    let avgPower: Int? // watts
    let avgHeartRate: Int? // bpm
    let avgSpeed: Double // km/h
    
    init(id: UUID = UUID(), segmentID: UUID, athleteName: String, duration: TimeInterval, date: Date = Date(), avgPower: Int? = nil, avgHeartRate: Int? = nil, avgSpeed: Double) {
        self.id = id
        self.segmentID = segmentID
        self.athleteName = athleteName
        self.duration = duration
        self.date = date
        self.avgPower = avgPower
        self.avgHeartRate = avgHeartRate
        self.avgSpeed = avgSpeed
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedSpeed: String {
        return String(format: "%.1f km/h", avgSpeed)
    }
}

