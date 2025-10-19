//
//  CyclingActivity.swift
//  FietsRouteMee
//
//  Strava-style Activity Tracking
//

import Foundation
import CoreLocation

struct CyclingActivity: Identifiable, Codable {
    let id: UUID
    var name: String
    var startDate: Date
    var endDate: Date?
    var duration: TimeInterval // seconds
    var distance: Double // meters
    var avgSpeed: Double // km/h
    var maxSpeed: Double // km/h
    var elevationGain: Double // meters
    var calories: Double
    var avgHeartRate: Int?
    var maxHeartRate: Int?
    var avgPower: Int? // watts
    var maxPower: Int? // watts
    var trackPoints: [TrackPoint]
    var pausedDuration: TimeInterval
    var bikeType: BikeType
    var weather: WeatherCondition?
    
    init(id: UUID = UUID(), name: String = "Morning Ride", startDate: Date = Date(), bikeType: BikeType = .city) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = nil
        self.duration = 0
        self.distance = 0
        self.avgSpeed = 0
        self.maxSpeed = 0
        self.elevationGain = 0
        self.calories = 0
        self.avgHeartRate = nil
        self.maxHeartRate = nil
        self.avgPower = nil
        self.maxPower = nil
        self.trackPoints = []
        self.pausedDuration = 0
        self.bikeType = bikeType
        self.weather = nil
    }
    
    var isActive: Bool {
        return endDate == nil
    }
    
    var movingTime: TimeInterval {
        return duration - pausedDuration
    }
    
    var pace: TimeInterval {
        // min/km
        guard distance > 0 else { return 0 }
        return (movingTime / 60.0) / (distance / 1000.0)
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%dh %02dm %02ds", hours, minutes, seconds)
        } else {
            return String(format: "%dm %02ds", minutes, seconds)
        }
    }
    
    var formattedDistance: String {
        if distance >= 1000 {
            return String(format: "%.2f km", distance / 1000.0)
        } else {
            return String(format: "%.0f m", distance)
        }
    }
    
    var formattedAvgSpeed: String {
        return String(format: "%.1f km/h", avgSpeed)
    }
    
    var formattedElevation: String {
        return String(format: "%.0f m", elevationGain)
    }
    
    var formattedCalories: String {
        return String(format: "%.0f kcal", calories)
    }
}

struct TrackPoint: Codable, Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let elevation: Double
    let timestamp: Date
    let speed: Double // m/s
    let heartRate: Int?
    let power: Int? // watts
    
    init(id: UUID = UUID(), coordinate: CLLocationCoordinate2D, elevation: Double, timestamp: Date, speed: Double, heartRate: Int? = nil, power: Int? = nil) {
        self.id = id
        self.coordinate = coordinate
        self.elevation = elevation
        self.timestamp = timestamp
        self.speed = speed
        self.heartRate = heartRate
        self.power = power
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, latitude, longitude, elevation, timestamp, speed, heartRate, power
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        let lat = try container.decode(Double.self, forKey: .latitude)
        let lon = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        elevation = try container.decode(Double.self, forKey: .elevation)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        speed = try container.decode(Double.self, forKey: .speed)
        heartRate = try container.decodeIfPresent(Int.self, forKey: .heartRate)
        power = try container.decodeIfPresent(Int.self, forKey: .power)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(elevation, forKey: .elevation)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(speed, forKey: .speed)
        try container.encodeIfPresent(heartRate, forKey: .heartRate)
        try container.encodeIfPresent(power, forKey: .power)
    }
}

struct WeatherCondition: Codable {
    let temperature: Double // Celsius
    let condition: String // e.g., "Clear", "Cloudy", "Rain"
    let windSpeed: Double // km/h
    let humidity: Int // percentage
}

// MARK: - Activity Statistics
struct ActivityStatistics {
    var totalDistance: Double = 0
    var totalDuration: TimeInterval = 0
    var totalElevation: Double = 0
    var totalCalories: Double = 0
    var totalActivities: Int = 0
    var avgSpeed: Double = 0
    
    var formattedTotalDistance: String {
        return String(format: "%.1f km", totalDistance / 1000.0)
    }
    
    var formattedTotalTime: String {
        let hours = Int(totalDuration) / 3600
        return String(format: "%dh", hours)
    }
}

