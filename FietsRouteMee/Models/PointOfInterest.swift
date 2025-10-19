//
//  PointOfInterest.swift
//  FietsRouteMee
//
//  Community Highlights & POI's (Komoot-style)
//

import Foundation
import CoreLocation

struct PointOfInterest: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var coordinate: CLLocationCoordinate2D
    var category: POICategory
    var rating: Double // 0-5
    var photos: [Data] // Image data
    var tips: [String]
    var createdBy: String
    var createdAt: Date
    var likes: Int
    
    init(id: UUID = UUID(), name: String, description: String, coordinate: CLLocationCoordinate2D, category: POICategory, rating: Double = 0, photos: [Data] = [], tips: [String] = [], createdBy: String = "System", createdAt: Date = Date(), likes: Int = 0) {
        self.id = id
        self.name = name
        self.description = description
        self.coordinate = coordinate
        self.category = category
        self.rating = rating
        self.photos = photos
        self.tips = tips
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.likes = likes
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, name, description, latitude, longitude, category, rating, photos, tips, createdBy, createdAt, likes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        let lat = try container.decode(Double.self, forKey: .latitude)
        let lon = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        category = try container.decode(POICategory.self, forKey: .category)
        rating = try container.decode(Double.self, forKey: .rating)
        photos = try container.decode([Data].self, forKey: .photos)
        tips = try container.decode([String].self, forKey: .tips)
        createdBy = try container.decode(String.self, forKey: .createdBy)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        likes = try container.decode(Int.self, forKey: .likes)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(category, forKey: .category)
        try container.encode(rating, forKey: .rating)
        try container.encode(photos, forKey: .photos)
        try container.encode(tips, forKey: .tips)
        try container.encode(createdBy, forKey: .createdBy)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(likes, forKey: .likes)
    }
}

enum POICategory: String, Codable, CaseIterable {
    case viewpoint = "Uitzichtpunt"
    case cafe = "Café"
    case restaurant = "Restaurant"
    case bikeShop = "Fietsenmaker"
    case parking = "Parkeren"
    case fountain = "Drinkwater"
    case shelter = "Schuilplaats"
    case historic = "Historisch"
    case nature = "Natuur"
    case photo = "Foto Spot"
    
    var displayName: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .viewpoint: return "eye.fill"
        case .cafe: return "cup.and.saucer.fill"
        case .restaurant: return "fork.knife"
        case .bikeShop: return "wrench.and.screwdriver.fill"
        case .parking: return "parkingsign.circle.fill"
        case .fountain: return "drop.fill"
        case .shelter: return "house.fill"
        case .historic: return "building.columns.fill"
        case .nature: return "leaf.fill"
        case .photo: return "camera.fill"
        }
    }
    
    var color: String {
        switch self {
        case .viewpoint: return "#007AFF"
        case .cafe: return "#8B4513"
        case .restaurant: return "#FF3B30"
        case .bikeShop: return "#FF9500"
        case .parking: return "#5856D6"
        case .fountain: return "#5AC8FA"
        case .shelter: return "#34C759"
        case .historic: return "#AF52DE"
        case .nature: return "#30D158"
        case .photo: return "#FF2D55"
        }
    }
}

