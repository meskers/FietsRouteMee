//
//  POIManager.swift
//  FietsRouteMee
//
//  Community Highlights & POI Manager
//

import Foundation
import CoreLocation
import Combine

@MainActor
class POIManager: ObservableObject {
    static let shared = POIManager()
    
    @Published var pois: [PointOfInterest] = []
    @Published var nearbyPOIs: [PointOfInterest] = []
    
    private let poisKey = "points_of_interest"
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadPOIs()
        if pois.isEmpty {
            createDefaultPOIs()
        }
    }
    
    // MARK: - POI Management
    
    func addPOI(_ poi: PointOfInterest) {
        pois.append(poi)
        savePOIs()
        print("✅ POI: Added '\(poi.name)'")
    }
    
    func updatePOI(_ poi: PointOfInterest) {
        if let index = pois.firstIndex(where: { $0.id == poi.id }) {
            pois[index] = poi
            savePOIs()
            print("✅ POI: Updated '\(poi.name)'")
        }
    }
    
    func deletePOI(_ poi: PointOfInterest) {
        pois.removeAll { $0.id == poi.id }
        savePOIs()
        print("✅ POI: Deleted '\(poi.name)'")
    }
    
    func likePOI(_ poi: PointOfInterest) {
        if let index = pois.firstIndex(where: { $0.id == poi.id }) {
            pois[index].likes += 1
            savePOIs()
            print("👍 POI: Liked '\(poi.name)'")
        }
    }
    
    // MARK: - Search & Filter
    
    func findNearbyPOIs(to coordinate: CLLocationCoordinate2D, radius: Double = 5000) {
        nearbyPOIs = pois.filter { poi in
            poi.coordinate.distanceTo(coordinate) <= radius
        }.sorted { poi1, poi2 in
            poi1.coordinate.distanceTo(coordinate) < poi2.coordinate.distanceTo(coordinate)
        }
        print("📍 Found \(nearbyPOIs.count) POIs within \(radius/1000)km")
    }
    
    func getPOIs(by category: POICategory) -> [PointOfInterest] {
        return pois.filter { $0.category == category }
    }
    
    func searchPOIs(query: String) -> [PointOfInterest] {
        guard !query.isEmpty else { return pois }
        return pois.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.description.localizedCaseInsensitiveContains(query) ||
            $0.tips.contains(where: { $0.localizedCaseInsensitiveContains(query) })
        }
    }
    
    // MARK: - Persistence
    
    private func savePOIs() {
        do {
            // MEMORY OPTIMIZATION: Limit saved POIs and remove image data
            var poisToSave = Array(pois.prefix(50))
            
            // Remove photo data to save memory (photos should be stored separately)
            for i in 0..<poisToSave.count {
                poisToSave[i].photos = []
            }
            
            let data = try JSONEncoder().encode(poisToSave)
            
            // Check data size
            let sizeInMB = Double(data.count) / 1_048_576
            if sizeInMB > 1.0 {
                print("⚠️ POI: Data too large (\(String(format: "%.2f", sizeInMB))MB), reducing...")
                poisToSave = Array(poisToSave.prefix(25))
                let reducedData = try JSONEncoder().encode(poisToSave)
                userDefaults.set(reducedData, forKey: poisKey)
                print("ℹ️ POI: Saved \(poisToSave.count) POIs (reduced)")
            } else {
                userDefaults.set(data, forKey: poisKey)
                print("ℹ️ POI: Saved \(poisToSave.count) POIs")
            }
        } catch {
            print("❌ POI: Failed to save: \(error)")
        }
    }
    
    private func loadPOIs() {
        guard let data = userDefaults.data(forKey: poisKey) else {
            print("ℹ️ POI: No saved POIs found")
            return
        }
        
        do {
            pois = try JSONDecoder().decode([PointOfInterest].self, from: data)
            print("✅ POI: Loaded \(pois.count) POIs")
        } catch {
            print("❌ POI: Failed to load: \(error)")
            pois = []
        }
    }
    
    // MARK: - Default POIs (Netherlands cycling highlights)
    
    private func createDefaultPOIs() {
        let defaultPOIs: [PointOfInterest] = [
            // Amsterdam Area
            PointOfInterest(
                name: "Vondelpark",
                description: "Het grootste stadspark van Amsterdam, perfect voor een ontspannen fietstocht",
                coordinate: CLLocationCoordinate2D(latitude: 52.3579, longitude: 4.8686),
                category: .nature,
                rating: 4.7,
                tips: ["Bezoek het openluchttheater", "Stop bij het Blauwe Theehuis"],
                createdBy: "FietsRouteMee",
                likes: 234
            ),
            PointOfInterest(
                name: "Café de Reiger",
                description: "Gezellig bruin café met heerlijke lunch en koffie",
                coordinate: CLLocationCoordinate2D(latitude: 52.3780, longitude: 4.8742),
                category: .cafe,
                rating: 4.5,
                tips: ["Probeer de uitsmijter", "Prachtig terras"],
                createdBy: "FietsRouteMee",
                likes: 156
            ),
            PointOfInterest(
                name: "Fietsenmaker Mokum",
                description: "Snelle service, vriendelijke eigenaar",
                coordinate: CLLocationCoordinate2D(latitude: 52.3667, longitude: 4.8945),
                category: .bikeShop,
                rating: 4.8,
                tips: ["Reserveer je band", "Geopend tot 19:00"],
                createdBy: "FietsRouteMee",
                likes: 89
            ),
            
            // Utrecht Area
            PointOfInterest(
                name: "Pandhof Domkerk",
                description: "Verborgen kloostertuin in het centrum, rust en historie",
                coordinate: CLLocationCoordinate2D(latitude: 52.0908, longitude: 5.1214),
                category: .historic,
                rating: 4.6,
                tips: ["Gratis toegang", "Mooi voor foto's"],
                createdBy: "FietsRouteMee",
                likes: 178
            ),
            PointOfInterest(
                name: "Máximapark",
                description: "Modern stadspark met glooiende heuvels en waterpartijen",
                coordinate: CLLocationCoordinate2D(latitude: 52.0673, longitude: 5.0986),
                category: .nature,
                rating: 4.4,
                tips: ["Mooi uitzicht vanaf de heuvels", "Veel speelvoorzieningen"],
                createdBy: "FietsRouteMee",
                likes: 201
            ),
            
            // Gelderland
            PointOfInterest(
                name: "Posbank Uitzichtpunt",
                description: "Spectaculair uitzicht over de Veluwe, vooral bij zonsondergang",
                coordinate: CLLocationCoordinate2D(latitude: 52.0234, longitude: 5.9654),
                category: .viewpoint,
                rating: 4.9,
                tips: ["Kom vroeg voor zonsopgang", "Heide bloeit in augustus"],
                createdBy: "FietsRouteMee",
                likes: 412
            ),
            PointOfInterest(
                name: "Natuurpoort Hoge Veluwe",
                description: "Ingang tot Nationaal Park de Hoge Veluwe",
                coordinate: CLLocationCoordinate2D(latitude: 52.0543, longitude: 5.8123),
                category: .nature,
                rating: 4.8,
                tips: ["Gratis witte fietsen beschikbaar", "Bezoek het Kröller-Müller Museum"],
                createdBy: "FietsRouteMee",
                likes: 345
            )
        ]
        
        pois = defaultPOIs
        savePOIs()
        print("✅ POI: Created \(defaultPOIs.count) default POIs")
    }
    
    func clearAll() {
        pois.removeAll()
        nearbyPOIs.removeAll()
        userDefaults.removeObject(forKey: poisKey)
        print("ℹ️ POI: Cleared all POIs")
    }
}

