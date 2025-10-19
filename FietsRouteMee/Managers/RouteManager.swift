//
//  RouteManager.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 08/10/2025.
//

import Foundation
@preconcurrency import MapKit
import CoreLocation
import Combine

enum RouteError: Error, LocalizedError {
    case noRouteFound
    case invalidCoordinates
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .noRouteFound:
            return "Geen route gevonden tussen de opgegeven locaties"
        case .invalidCoordinates:
            return "Ongeldige coördinaten opgegeven"
        case .networkError:
            return "Netwerkfout bij het berekenen van de route"
        }
    }
}

@MainActor
class RouteManager: ObservableObject {
    static let shared = RouteManager()
    
    @Published var routes: [BikeRoute] = []
    @Published var isCalculating = false
    @Published var errorMessage: String?
    
    private let coreDataManager = CoreDataManager.shared
    private let settingsManager = AppSettingsManager.shared
    private let graphHopperService = GraphHopperService.shared
    private let mapLibreService = MapLibreService.shared
    private let fietsknooppuntenService = FietsknooppuntenService.shared
    
    private init() {
        // Monitor memory warnings
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleMemoryWarning()
            }
        }
    }
    
    private func handleMemoryWarning() {
        print("⚠️ RouteManager: Memory warning received, clearing excess routes")
        // Keep only the 3 most recent routes
        limitRoutesInMemory(maxRoutes: 3)
    }
    
    nonisolated func calculateRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, 
                           waypoints: [CLLocationCoordinate2D] = [], bikeType: BikeType? = nil) {
        
        print("🚴‍♂️ RouteManager: Starting REAL CYCLING route calculation from \(start) to \(end)")
        
        Task { @MainActor in
            isCalculating = true
            errorMessage = nil
            
            // Get bike type from settings or parameter
            let selectedBikeType = bikeType ?? settingsManager.selectedBikeType
            let preferences = settingsManager.getRoutePreferences()
            
            print("🚴‍♂️ RouteManager: Using bike type: \(selectedBikeType.displayName)")
            print("🚴‍♂️ RouteManager: Using OpenRouteService for REAL cycling routes")
        
            do {
                // Try OpenRouteService first for real cycling routes
                let bikeRoute = try await calculateOpenRouteServiceRoute(
                    from: start,
                    to: end,
                    waypoints: waypoints,
                    bikeType: selectedBikeType,
                    preferences: preferences
                )
                
                print("✅ RouteManager: OpenRouteService route calculated - Distance: \(bikeRoute.distance)m, Duration: \(bikeRoute.duration)s")
                print("✅ RouteManager: Route has \(bikeRoute.polyline.count) coordinates and \(bikeRoute.instructions.count) turn-by-turn instructions")
                
                // Check for duplicates
                let existingRoute = self.routes.first { existingRoute in
                    abs(existingRoute.startLocation.latitude - bikeRoute.startLocation.latitude) < 0.0001 &&
                    abs(existingRoute.startLocation.longitude - bikeRoute.startLocation.longitude) < 0.0001 &&
                    abs(existingRoute.endLocation.latitude - bikeRoute.endLocation.latitude) < 0.0001 &&
                    abs(existingRoute.endLocation.longitude - bikeRoute.endLocation.longitude) < 0.0001
                }
                
                if existingRoute == nil {
                    self.routes.append(bikeRoute)
                    self.coreDataManager.saveRoute(bikeRoute)
                    print("✅ RouteManager: Route added. Total routes: \(self.routes.count)")
                } else {
                    print("⚠️ RouteManager: Route already exists, skipping duplicate")
                }
                
                self.isCalculating = false
                
            } catch let error {
                print("❌ RouteManager: OpenRouteService failed, falling back to MapKit: \(error.localizedDescription)")
                
                // Fallback to MapKit if OpenRouteService fails
                do {
                    let bikeRoute = try await calculateMapKitRoute(
                        from: start,
                        to: end,
                        waypoints: waypoints,
                        bikeType: selectedBikeType,
                        preferences: preferences
                    )
                    
                    print("✅ RouteManager: MapKit fallback route calculated")
                    
                    // Check for duplicates
                    let existingRoute = self.routes.first { existingRoute in
                        abs(existingRoute.startLocation.latitude - bikeRoute.startLocation.latitude) < 0.0001 &&
                        abs(existingRoute.startLocation.longitude - bikeRoute.startLocation.longitude) < 0.0001 &&
                        abs(existingRoute.endLocation.latitude - bikeRoute.endLocation.latitude) < 0.0001 &&
                        abs(existingRoute.endLocation.longitude - bikeRoute.endLocation.longitude) < 0.0001
                    }
                    
                    if existingRoute == nil {
                        self.routes.append(bikeRoute)
                        self.coreDataManager.saveRoute(bikeRoute)
                        print("✅ RouteManager: Fallback route added. Total routes: \(self.routes.count)")
                    }
                    
                    self.isCalculating = false
                    
                } catch let fallbackError {
                    print("❌ RouteManager: Both OpenRouteService and MapKit failed: \(fallbackError.localizedDescription)")
                    self.errorMessage = "Geen fietsroute gevonden. Probeer andere locaties."
                    self.isCalculating = false
                }
            }
        }
    }
    
    func clearRoutes() {
        routes.removeAll()
        print("ℹ️ RouteManager: Cleared all routes from memory")
    }
    
    func removeRoute(_ route: BikeRoute) {
        routes.removeAll { $0.id == route.id }
        print("ℹ️ RouteManager: Removed route from memory")
    }
    
    func limitRoutesInMemory(maxRoutes: Int = 10) {
        // MEMORY OPTIMIZATION: Keep only most recent routes in memory
        if routes.count > maxRoutes {
            let sortedRoutes = routes.sorted { $0.createdAt > $1.createdAt }
            routes = Array(sortedRoutes.prefix(maxRoutes))
            print("⚠️ RouteManager: Limited routes in memory to \(maxRoutes) (was \(sortedRoutes.count))")
        }
    }
    
    func loadSavedRoutes() async {
        await MainActor.run {
            routes = coreDataManager.savedRoutes.compactMap { entity in
                convertEntityToRoute(entity)
            }
        }
    }
    
    func deleteRoute(_ route: BikeRoute) {
        routes.removeAll { $0.id == route.id }
        coreDataManager.deleteRoute(route)
    }
    
    func getRecentRoutes(limit: Int = 10) -> [BikeRoute] {
        return Array(routes.sorted { $0.createdAt > $1.createdAt }.prefix(limit))
    }
    
    // MARK: - Private Methods
    
    private func calculateOpenRouteServiceRoute(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        waypoints: [CLLocationCoordinate2D],
        bikeType: BikeType
    ) async throws -> BikeRoute {
        
        print("🌐 RouteManager: Using OpenRouteService for bicycle routing")
        
        let openRouteService = OpenRouteService.shared
        return try await openRouteService.calculateCyclingRoute(
            from: start,
            to: end,
            waypoints: waypoints,
            bikeType: bikeType
        )
    }
    
    private func selectBestBicycleRoute(_ routes: [MKRoute], bikeType: BikeType, preferences: RoutePreferences) -> MKRoute {
        guard routes.count > 1 else {
            return routes.first!
        }
        
        print("🚴‍♂️ RouteManager: Evaluating \(routes.count) routes for bicycle suitability")
        
        // Score each route based on bicycle-friendliness
        let scoredRoutes = routes.map { route in
            let score = calculateBicycleScore(route, bikeType: bikeType, preferences: preferences)
            return (route: route, score: score)
        }
        
        // Sort by score (higher is better)
        let sortedRoutes = scoredRoutes.sorted { $0.score > $1.score }
        
        let bestRoute = sortedRoutes.first!.route
        let bestScore = sortedRoutes.first!.score
        
        print("🚴‍♂️ RouteManager: Best route score: \(bestScore) (distance: \(bestRoute.distance)m)")
        
        return bestRoute
    }
    
    private func calculateBicycleScore(_ route: MKRoute, bikeType: BikeType, preferences: RoutePreferences) -> Double {
        var score = 0.0
        
        // Distance factor (shorter is generally better for bikes)
        let distanceKm = route.distance / 1000
        score += max(0, 100 - distanceKm * 2) // Base score decreases with distance
        
        // Duration factor (shorter is better)
        let durationHours = route.expectedTravelTime / 3600
        score += max(0, 50 - durationHours * 10)
        
        // Analyze route steps for bicycle-friendliness
        let bicycleFriendlySteps = route.steps.filter { step in
            let instruction = step.instructions.lowercased()
            return instruction.contains("fietspad") || 
                   instruction.contains("bike") ||
                   instruction.contains("cycle") ||
                   instruction.contains("bicycle") ||
                   !instruction.contains("snelweg") &&
                   !instruction.contains("highway") &&
                   !instruction.contains("motorway")
        }
        
        let bicycleFriendlyRatio = Double(bicycleFriendlySteps.count) / Double(route.steps.count)
        score += bicycleFriendlyRatio * 100
        
        // Prefer routes that avoid highways if requested
        if preferences.avoidHighways {
            let highwaySteps = route.steps.filter { step in
                let instruction = step.instructions.lowercased()
                return instruction.contains("snelweg") || 
                       instruction.contains("highway") ||
                       instruction.contains("motorway")
            }
            let highwayRatio = Double(highwaySteps.count) / Double(route.steps.count)
            score += (1.0 - highwayRatio) * 50
        }
        
        // Prefer routes with bike paths if requested
        if preferences.preferBikePaths {
            let bikePathSteps = route.steps.filter { step in
                let instruction = step.instructions.lowercased()
                return instruction.contains("fietspad") || 
                       instruction.contains("bike path") ||
                       instruction.contains("cycle path")
            }
            let bikePathRatio = Double(bikePathSteps.count) / Double(route.steps.count)
            score += bikePathRatio * 75
        }
        
        // Bike type specific preferences
        switch bikeType {
        case .city:
            // Prefer shorter, urban routes
            score += max(0, 50 - distanceKm)
        case .road:
            // Prefer longer, faster routes
            score += min(50, distanceKm * 2)
        case .mountain:
            // Prefer nature routes
            if preferences.preferNature {
                score += 25
            }
        case .electric:
            // Prefer moderate distance routes
            score += max(0, 25 - abs(distanceKm - 15))
        case .cargo:
            // Prefer shorter, safer routes
            score += max(0, 75 - distanceKm * 3)
        }
        
        return score
    }
    
    private func calculateOpenRouteServiceRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, 
                                              waypoints: [CLLocationCoordinate2D], bikeType: BikeType, 
                                              preferences: RoutePreferences) async throws -> BikeRoute {
        
        print("🚴‍♂️ RouteManager: Using OpenRouteService for REAL cycling routes")
        
        // Use OpenRouteService for bicycle-specific routing
        let openRouteService = OpenRouteService.shared
        let bikeRoute = try await openRouteService.calculateCyclingRoute(
            from: start,
            to: end,
            waypoints: waypoints,
            bikeType: bikeType
        )
        
        print("✅ RouteManager: OpenRouteService calculated real cycling route")
        return bikeRoute
    }
    
    private func calculateMapKitRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, 
                                    waypoints: [CLLocationCoordinate2D], bikeType: BikeType, 
                                    preferences: RoutePreferences) async throws -> BikeRoute {
        
        // Create MapKit request
        let request = MKDirections.Request()
        
        // Set start and end locations
        let startPlacemark = MKPlacemark(coordinate: start)
        let endPlacemark = MKPlacemark(coordinate: end)
        request.source = MKMapItem(placemark: startPlacemark)
        request.destination = MKMapItem(placemark: endPlacemark)
        
        // Use walking transport type (bicycle-friendly)
        request.transportType = .walking
        request.requestsAlternateRoutes = true // Get multiple routes to choose best bike route
        
        // Configure for bicycle-friendly routing
        if preferences.avoidHighways {
            request.tollPreference = .avoid
        }
        
        // Additional bicycle-specific preferences
        request.requestsAlternateRoutes = true
        
        // Note: MapKit doesn't support waypoints in MKDirections.Request
        // For now, we'll calculate direct routes only
        // TODO: Implement waypoint support using multiple route calculations
        
        print("🗺️ RouteManager: Sending route request to MapKit with transport type: \(request.transportType.rawValue)")
        
        // Calculate route
        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        
        guard !response.routes.isEmpty else {
            throw RouteError.noRouteFound
        }
        
        print("✅ RouteManager: Received \(response.routes.count) route(s) from MapKit")
        
        // Choose the best bicycle route from alternatives
        let bestRoute = selectBestBicycleRoute(response.routes, bikeType: bikeType, preferences: preferences)
        
        print("🚴‍♂️ RouteManager: Selected best bicycle route - Distance: \(bestRoute.distance)m")
        
        // Convert to BikeRoute
        return convertMapKitRoute(bestRoute, start: start, end: end, waypoints: waypoints, bikeType: bikeType)
    }
    
    private func convertMapKitRoute(_ route: MKRoute, start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, waypoints: [CLLocationCoordinate2D], bikeType: BikeType = .city) -> BikeRoute {
        // MEMORY OPTIMIZATION: Limit polyline points to prevent memory issues
        let allCoordinates = route.polyline.coordinates
        let maxPoints = 300
        
        let coordinates: [CLLocationCoordinate2D]
        if allCoordinates.count > maxPoints {
            // Sample points evenly
            let step = Double(allCoordinates.count) / Double(maxPoints)
            coordinates = (0..<maxPoints).compactMap { i in
                let index = Int(Double(i) * step)
                return index < allCoordinates.count ? allCoordinates[index] : nil
            }
            print("⚠️ RouteManager: Reduced polyline from \(allCoordinates.count) to \(coordinates.count) points")
        } else {
            coordinates = allCoordinates
        }
        
        // Convert MapKit steps to our RouteInstruction format
        let instructions: [RouteInstruction] = route.steps.map { step in
            let instructionType: RouteInstruction.InstructionType
            switch step.instructions.lowercased() {
            case let instruction where instruction.contains("links") || instruction.contains("left"):
                instructionType = .turnLeft
            case let instruction where instruction.contains("rechts") || instruction.contains("right"):
                instructionType = .turnRight
            case let instruction where instruction.contains("rechtdoor") || instruction.contains("straight"):
                instructionType = .straight
            case let instruction where instruction.contains("bestemming") || instruction.contains("destination"):
                instructionType = .destination
            default:
                instructionType = .straight
            }
            
            return RouteInstruction(
                instruction: step.instructions,
                distance: step.distance,
                coordinate: step.polyline.coordinate,
                type: instructionType
            )
        }
        
        // Calculate cycling-specific metrics based on bike type
        let cyclingDuration = calculateCyclingDuration(distance: route.distance, bikeType: bikeType)
        let difficulty = determineDifficulty(distance: route.distance, elevation: [], steps: instructions, bikeType: bikeType)
        let surface = determineSurface(for: coordinates, preferences: settingsManager.getRoutePreferences(), bikeType: bikeType)
        
        // Adjust distance for bike type (some bikes take longer routes)
        let adjustedDistance = adjustDistanceForBikeType(route.distance, bikeType: bikeType)
        
        return BikeRoute(
            startLocation: start,
            endLocation: end,
            waypoints: waypoints,
            distance: adjustedDistance,
            duration: cyclingDuration,
            elevation: generateElevationProfile(for: coordinates),
            instructions: instructions,
            polyline: coordinates,
            difficulty: difficulty,
            surface: surface,
            bikeType: bikeType, // Pass the bike type
            createdAt: Date(),
            isFavorite: false
        )
    }
    
    private func convertEntityToRoute(_ entity: BikeRouteEntity) -> BikeRoute? {
        guard let polylineData = entity.polylineData as? Data,
              let instructionsData = entity.instructionsData as? Data else {
            print("⚠️ RouteManager: Invalid entity data, skipping")
            return nil
        }
        
        // Decode polyline coordinates - try both JSON and NSKeyedArchiver formats
        let polyline: [CLLocationCoordinate2D]
        do {
            // First try JSON format (old routes)
            if let jsonString = String(data: polylineData, encoding: .utf8),
               let jsonData = jsonString.data(using: .utf8),
               let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
                polyline = jsonArray.compactMap { dict in
                    guard let lat = dict["lat"] as? Double,
                          let lng = dict["lng"] as? Double else { return nil }
                    return CLLocationCoordinate2D(latitude: lat, longitude: lng)
                }
                print("✅ RouteManager: Decoded polyline from JSON format (\(polyline.count) points)")
            } else {
                // Try NSKeyedArchiver format (new routes)
                if #available(iOS 11.0, *) {
                    let coordinates = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: polylineData) as? [CLLocationCoordinate2D] ?? []
                    polyline = coordinates
                } else {
                    let coordinates = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(polylineData) as? [CLLocationCoordinate2D] ?? []
                    polyline = coordinates
                }
                print("✅ RouteManager: Decoded polyline from NSKeyedArchiver format (\(polyline.count) points)")
            }
        } catch {
            print("⚠️ RouteManager: Failed to decode polyline: \(error)")
            polyline = []
        }
        
        // Decode instructions - try both JSON and NSKeyedArchiver formats
        let instructions: [RouteInstruction]
        do {
            // First try JSON format (old routes)
            if let jsonString = String(data: instructionsData, encoding: .utf8),
               let jsonData = jsonString.data(using: .utf8),
               let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
                instructions = jsonArray.compactMap { dict in
                    guard let instruction = dict["instruction"] as? String,
                          let distance = dict["distance"] as? Double,
                          let lat = dict["lat"] as? Double,
                          let lng = dict["lng"] as? Double,
                          let typeString = dict["type"] as? String,
                          let type = RouteInstruction.InstructionType(rawValue: typeString) else { return nil }
                    
                    return RouteInstruction(
                        instruction: instruction,
                        distance: distance,
                        coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                        type: type
                    )
                }
                print("✅ RouteManager: Decoded instructions from JSON format (\(instructions.count) instructions)")
            } else {
                // Try NSKeyedArchiver format (new routes)
                if #available(iOS 11.0, *) {
                    instructions = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: instructionsData) as? [RouteInstruction] ?? []
                } else {
                    instructions = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(instructionsData) as? [RouteInstruction] ?? []
                }
                print("✅ RouteManager: Decoded instructions from NSKeyedArchiver format (\(instructions.count) instructions)")
            }
        } catch {
            print("⚠️ RouteManager: Failed to decode instructions: \(error)")
            instructions = []
        }
        
        // Decode elevation - try both JSON and NSKeyedArchiver formats
        let elevation: [Double]
        if let elevationData = entity.elevationData as? Data {
            do {
                // First try JSON format (old routes)
                if let jsonString = String(data: elevationData, encoding: .utf8),
                   let jsonData = jsonString.data(using: .utf8),
                   let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [Double] {
                    elevation = jsonArray
                    print("✅ RouteManager: Decoded elevation from JSON format (\(elevation.count) points)")
                } else {
                    // Try NSKeyedArchiver format (new routes)
                    if #available(iOS 11.0, *) {
                        elevation = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: elevationData) as? [Double] ?? []
                    } else {
                        elevation = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(elevationData) as? [Double] ?? []
                    }
                    print("✅ RouteManager: Decoded elevation from NSKeyedArchiver format (\(elevation.count) points)")
                }
            } catch {
                print("⚠️ RouteManager: Failed to decode elevation: \(error)")
                elevation = []
            }
        } else {
            elevation = []
        }
        
        return BikeRoute(
            startLocation: CLLocationCoordinate2D(latitude: entity.startLatitude, longitude: entity.startLongitude),
            endLocation: CLLocationCoordinate2D(latitude: entity.endLatitude, longitude: entity.endLongitude),
            waypoints: [], // No waypoints stored in current model
            distance: entity.distance,
            duration: entity.duration,
            elevation: elevation,
            instructions: instructions,
            polyline: polyline,
            difficulty: RouteDifficulty(rawValue: entity.difficulty ?? "moderate") ?? .moderate,
            surface: RouteSurface(rawValue: entity.surface ?? "mixed") ?? .mixed,
            bikeType: BikeType(rawValue: entity.bikeType ?? "city") ?? .city,
            createdAt: entity.createdAt ?? Date(),
            isFavorite: entity.isFavorite
        )
    }
    
    private func calculateCyclingDuration(distance: CLLocationDistance, bikeType: BikeType) -> TimeInterval {
        // Different bike types have different average speeds
        let speedKmh: Double
        switch bikeType {
        case .city:
            speedKmh = 15.0 // Comfortable city pace
        case .mountain:
            speedKmh = 12.0 // Slower due to terrain
        case .road:
            speedKmh = 25.0 // Fast road bike
        case .electric:
            speedKmh = 22.0 // E-bike assisted speed
        case .cargo:
            speedKmh = 12.0 // Slower due to weight
        }
        
        let speedMs = speedKmh * 1000 / 3600 // Convert to m/s
        let duration = distance / speedMs
        
        print("🚴‍♂️ RouteManager: Calculated duration for \(bikeType.displayName): \(Int(duration/60)) min at \(speedKmh) km/h")
        return duration
    }
    
    private func adjustDistanceForBikeType(_ distance: CLLocationDistance, bikeType: BikeType) -> CLLocationDistance {
        // Some bike types might take slightly different routes
        let multiplier: Double
        switch bikeType {
        case .city:
            multiplier = 1.0 // Standard route
        case .mountain:
            multiplier = 1.1 // Might take longer scenic routes
        case .road:
            multiplier = 0.95 // Might take more direct routes
        case .electric:
            multiplier = 1.0 // Standard route
        case .cargo:
            multiplier = 1.15 // Might avoid narrow paths, take longer routes
        }
        
        let adjustedDistance = distance * multiplier
        print("🚴‍♂️ RouteManager: Adjusted distance for \(bikeType.displayName): \(Int(distance))m → \(Int(adjustedDistance))m (×\(multiplier))")
        return adjustedDistance
    }
    
    private func determineDifficulty(distance: CLLocationDistance, elevation: [Double], steps: [RouteInstruction], bikeType: BikeType) -> RouteDifficulty {
        // Adjust difficulty based on bike type
        let baseDistance = distance / 1000 // Convert to km
        
        switch bikeType {
        case .electric:
            // E-bikes make everything easier
            if baseDistance < 10 {
                return .easy
            } else if baseDistance < 30 {
                return .moderate
            } else {
                return .hard
            }
        case .road:
            // Road bikes are efficient on paved roads
            if baseDistance < 20 {
                return .easy
            } else if baseDistance < 50 {
                return .moderate
            } else if baseDistance < 100 {
                return .hard
            } else {
                return .expert
            }
        case .mountain:
            // Mountain bikes handle rough terrain better
            if baseDistance < 15 {
                return .easy
            } else if baseDistance < 35 {
                return .moderate
            } else {
                return .hard
            }
        case .cargo:
            // Cargo bikes are harder to ride
            if baseDistance < 5 {
                return .easy
            } else if baseDistance < 15 {
                return .moderate
            } else {
                return .hard
            }
        case .city:
            // Standard city bike
            if baseDistance < 10 {
                return .easy
            } else if baseDistance < 25 {
                return .moderate
            } else {
                return .hard
            }
        }
    }
    
    private func determineSurface(for coordinates: [CLLocationCoordinate2D], preferences: RoutePreferences, bikeType: BikeType) -> RouteSurface {
        // Determine preferred surface based on bike type
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
        // Generate simple elevation profile
        return coordinates.map { _ in Double.random(in: 0...50) }
    }
    
    // MARK: - Service Integration
    
    private func convertBikeTypeToProfile(_ bikeType: BikeType) -> RoutingProfile {
        switch bikeType {
        case .city:
            return .bike
        case .mountain:
            return .mtb
        case .road:
            return .racingbike
        case .electric:
            return .ebike
        case .cargo:
            return .cargo
        }
    }
}

// MARK: - MKPolyline Extension

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords: [CLLocationCoordinate2D] = []
        let pointCount = self.pointCount
        let points = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: pointCount)
        
        self.getCoordinates(points, range: NSRange(location: 0, length: pointCount))
        
        for i in 0..<pointCount {
            coords.append(points[i])
        }
        
        points.deallocate()
        return coords
    }
}