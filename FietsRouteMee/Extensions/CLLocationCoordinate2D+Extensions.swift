//
//  CLLocationCoordinate2D+Extensions.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 08/10/2025.
//

import Foundation
import CoreLocation
import MapKit

extension CLLocationCoordinate2D {
    // Custom equality function to avoid Apple's warning about future Equatable conformance
    func isEqual(to coordinate: CLLocationCoordinate2D) -> Bool {
        return abs(self.latitude - coordinate.latitude) < 0.0001 && 
               abs(self.longitude - coordinate.longitude) < 0.0001
    }
    
    var isValid: Bool {
        return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180
    }
    
    nonisolated func distanceTo(_ coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let to = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return from.distance(from: to)
    }
    
    func bearingTo(_ coordinate: CLLocationCoordinate2D) -> Double {
        let lat1 = self.latitude * .pi / 180
        let lat2 = coordinate.latitude * .pi / 180
        let deltaLng = (coordinate.longitude - self.longitude) * .pi / 180
        
        let y = sin(deltaLng) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLng)
        
        let bearing = atan2(y, x) * 180 / .pi
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }
}

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return abs(lhs.latitude - rhs.latitude) < 1e-9 && abs(lhs.longitude - rhs.longitude) < 1e-9
    }
}

extension MKCoordinateSpan: @retroactive Equatable {
    public static func == (lhs: MKCoordinateSpan, rhs: MKCoordinateSpan) -> Bool {
        return abs(lhs.latitudeDelta - rhs.latitudeDelta) < 1e-9 && abs(lhs.longitudeDelta - rhs.longitudeDelta) < 1e-9
    }
}

extension MKCoordinateRegion: @retroactive Equatable {
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        return lhs.center == rhs.center && lhs.span == rhs.span
    }
}
