//
//  RouteFormatter.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 08/10/2025.
//

import Foundation
import CoreLocation

struct RouteFormatter {
    static func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
    
    static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return "\(hours)u \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    static func formatSpeed(_ speed: Double) -> String {
        return String(format: "%.1f km/h", speed)
    }
    
    static func formatElevation(_ elevation: Double) -> String {
        return "\(Int(elevation))m"
    }
    
    static func formatCoordinate(_ coordinate: CLLocationCoordinate2D) -> String {
        return String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
    }
    
    static func getDirectionName(from bearing: Double) -> String {
        switch bearing {
        case 0..<22.5, 337.5...360:
            return "Noord"
        case 22.5..<67.5:
            return "Noordoost"
        case 67.5..<112.5:
            return "Oost"
        case 112.5..<157.5:
            return "Zuidoost"
        case 157.5..<202.5:
            return "Zuid"
        case 202.5..<247.5:
            return "Zuidwest"
        case 247.5..<292.5:
            return "West"
        case 292.5..<337.5:
            return "Noordwest"
        default:
            return "Onbekend"
        }
    }
}
