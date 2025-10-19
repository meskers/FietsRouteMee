//
//  FietsKnooppunt.swift
//  FietsRouteMee
//
//  Nederlandse Fietsknooppunten Model
//

import Foundation
import CoreLocation
import MapKit

struct FietsKnooppunt: Identifiable, Codable {
    let id: UUID
    let number: Int
    let coordinate: CLLocationCoordinate2D
    let province: String
    let network: KnooppuntNetwork
    var connections: [Int] // Connected knooppunt numbers
    
    init(id: UUID = UUID(), number: Int, coordinate: CLLocationCoordinate2D, province: String, network: KnooppuntNetwork, connections: [Int] = []) {
        self.id = id
        self.number = number
        self.coordinate = coordinate
        self.province = province
        self.network = network
        self.connections = connections
    }
    
    var displayName: String {
        return "Knooppunt \(number)"
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, number, latitude, longitude, province, network, connections
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        number = try container.decode(Int.self, forKey: .number)
        let lat = try container.decode(Double.self, forKey: .latitude)
        let lon = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        province = try container.decode(String.self, forKey: .province)
        network = try container.decode(KnooppuntNetwork.self, forKey: .network)
        connections = try container.decode([Int].self, forKey: .connections)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(number, forKey: .number)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(province, forKey: .province)
        try container.encode(network, forKey: .network)
        try container.encode(connections, forKey: .connections)
    }
}

enum KnooppuntNetwork: String, Codable, CaseIterable {
    case fietsnetwerk = "Fietsnetwerk"
    case lf_routes = "LF Routes"
    case regioRoute = "Regio Route"
    
    var displayName: String {
        return rawValue
    }
    
    var color: String {
        switch self {
        case .fietsnetwerk: return "#34C759"
        case .lf_routes: return "#007AFF"
        case .regioRoute: return "#FF9500"
        }
    }
}

// MARK: - Knooppunt Route
struct KnooppuntRoute: Identifiable {
    let id = UUID()
    let knooppunten: [Int] // Sequence of knooppunt numbers
    var totalDistance: Double = 0
    var estimatedDuration: TimeInterval = 0
    
    var displaySequence: String {
        return knooppunten.map { String($0) }.joined(separator: " → ")
    }
}

