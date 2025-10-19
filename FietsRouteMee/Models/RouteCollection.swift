//
//  RouteCollection.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 16/10/2025.
//

import Foundation
import SwiftUI

struct RouteCollection: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var color: String // Hex color
    var routeIDs: [UUID]
    var coverImageData: Data?
    var createdAt: Date
    var isPublic: Bool
    
    init(id: UUID = UUID(), name: String, description: String = "", color: String = "#0066CC", routeIDs: [UUID] = [], coverImageData: Data? = nil, isPublic: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.color = color
        self.routeIDs = routeIDs
        self.coverImageData = coverImageData
        self.createdAt = Date()
        self.isPublic = isPublic
    }
    
    var colorValue: Color {
        Color(hex: color) ?? .blue
    }
    
    var routeCount: Int {
        routeIDs.count
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else { return "#000000" }
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

