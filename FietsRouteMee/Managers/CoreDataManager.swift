//
//  CoreDataManager.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 08/10/2025.
//

import Foundation
import CoreData
import CoreLocation
import Combine

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    let container: NSPersistentContainer
    
    @Published var savedRoutes: [BikeRouteEntity] = []
    @Published var isLoading = false
    
    private init() {
        container = NSPersistentContainer(name: "FietsRouteMee")
        
        // Configure store description BEFORE loading
        if let storeDescription = container.persistentStoreDescriptions.first {
            // Explicitly disable persistent history tracking
            storeDescription.setOption(false as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(false as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // Enable lightweight migration
            storeDescription.shouldMigrateStoreAutomatically = true
            storeDescription.shouldInferMappingModelAutomatically = true
            
            // Set file protection
            storeDescription.setOption(FileProtectionType.complete as NSObject, forKey: NSPersistentStoreFileProtectionKey)
        }
        
        // Load persistent store
        container.loadPersistentStores { description, error in
            if let error = error {
                print("❌ CoreData: Failed to load store: \(error.localizedDescription)")
                
                // Try to recover by removing corrupted store
                if let storeURL = description.url {
                    let fileManager = FileManager.default
                    print("⚠️ CoreData: Attempting to remove corrupted store...")
                    
                    // Remove all store files
                    try? fileManager.removeItem(at: storeURL)
                    try? fileManager.removeItem(at: storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm"))
                    try? fileManager.removeItem(at: storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal"))
                    
                    // Try loading again
                    self.container.loadPersistentStores { _, retryError in
                        if let retryError = retryError {
                            print("❌ CoreData: Recovery failed: \(retryError.localizedDescription)")
                            // Don't crash - just log and continue without persistence
                        } else {
                            print("✅ CoreData: Store recovered and loaded successfully")
                        }
                    }
                }
            } else {
                print("✅ CoreData: Store loaded successfully")
                if let storeURL = description.url {
                    print("📍 CoreData: Store location: \(storeURL.path)")
                }
            }
        }
        
        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        container.viewContext.undoManager = nil
        container.viewContext.shouldDeleteInaccessibleFaults = true
        
        // Don't load routes automatically - let MainTabView control this
        print("ℹ️ CoreData: CoreDataManager initialized - routes will be loaded on demand")
    }
    
    func saveRoute(_ route: BikeRoute) {
        // Check if CoreData is available
        guard container.persistentStoreCoordinator.persistentStores.count > 0 else {
            print("⚠️ CoreData: Cannot save route - no persistent stores available")
            return
        }
        
        // Save on main context to avoid concurrency issues
        let context = container.viewContext
        
        // Check if route already exists
        let fetchRequest: NSFetchRequest<BikeRouteEntity> = BikeRouteEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", route.id as CVarArg)
        
        do {
            let existingRoutes = try context.fetch(fetchRequest)
            if !existingRoutes.isEmpty {
                // Update existing route
                let existingRoute = existingRoutes.first!
                updateRouteEntity(existingRoute, with: route)
            } else {
                // Create new route
                let routeEntity = BikeRouteEntity(context: context)
                updateRouteEntity(routeEntity, with: route)
            }
            
            try context.save()
            loadSavedRoutes()
            print("✅ CoreData: Route saved successfully")
            
        } catch {
            print("❌ CoreData: Failed to save route: \(error.localizedDescription)")
        }
    }
    
    func deleteRoute(_ route: BikeRoute) {
        let context = container.viewContext
        
        let fetchRequest: NSFetchRequest<BikeRouteEntity> = BikeRouteEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", route.id as CVarArg)
        
        do {
            let routes = try context.fetch(fetchRequest)
            for routeEntity in routes {
                context.delete(routeEntity)
            }
            
            try context.save()
            loadSavedRoutes()
            
        } catch {
            print("Failed to delete route: \(error.localizedDescription)")
        }
    }
    
    func toggleFavorite(_ route: BikeRoute) {
        let context = container.viewContext
        
        let fetchRequest: NSFetchRequest<BikeRouteEntity> = BikeRouteEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", route.id as CVarArg)
        
        do {
            let routes = try context.fetch(fetchRequest)
            if let routeEntity = routes.first {
                routeEntity.isFavorite.toggle()
                try context.save()
                loadSavedRoutes()
            }
        } catch {
            print("Failed to toggle favorite: \(error.localizedDescription)")
        }
    }
    
    func getFavoriteRoutes() -> [BikeRoute] {
        return savedRoutes
            .filter { $0.isFavorite }
            .compactMap { convertToBikeRoute($0) }
    }
    
    func getRecentRoutes(limit: Int = 10) -> [BikeRoute] {
        return savedRoutes
            .sorted { ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) }
            .prefix(limit)
            .compactMap { convertToBikeRoute($0) }
    }
    
    private func updateRouteEntity(_ entity: BikeRouteEntity, with route: BikeRoute) {
        entity.id = route.id
        entity.startLatitude = route.startLocation.latitude
        entity.startLongitude = route.startLocation.longitude
        entity.endLatitude = route.endLocation.latitude
        entity.endLongitude = route.endLocation.longitude
        entity.distance = route.distance
        entity.duration = route.duration
        entity.difficulty = route.difficulty.rawValue
        entity.surface = route.surface.rawValue
        entity.bikeType = route.bikeType.rawValue
        entity.isFavorite = route.isFavorite
        entity.createdAt = route.createdAt
        
        // Store complex data as JSON
        entity.elevationData = try? JSONEncoder().encode(route.elevation) as NSData
        entity.polylineData = try? JSONEncoder().encode(route.polyline.map { ["lat": $0.latitude, "lng": $0.longitude] }) as NSData
        entity.instructionsData = try? JSONEncoder().encode(route.instructions) as NSData
        
        // Generate a name if not provided
        if entity.name == nil || entity.name?.isEmpty == true {
            entity.name = generateRouteName(for: route)
        }
    }
    
    private func convertToBikeRoute(_ entity: BikeRouteEntity) -> BikeRoute? {
        let startLocation = CLLocationCoordinate2D(latitude: entity.startLatitude, longitude: entity.startLongitude)
        let endLocation = CLLocationCoordinate2D(latitude: entity.endLatitude, longitude: entity.endLongitude)
        
        // Decode complex data
        var elevation: [Double] = []
        if let elevationData = entity.elevationData as? Data {
            elevation = (try? JSONDecoder().decode([Double].self, from: elevationData)) ?? []
        }
        
        var polyline: [CLLocationCoordinate2D] = []
        if let polylineData = entity.polylineData as? Data {
            let coordinates = (try? JSONDecoder().decode([[String: Double]].self, from: polylineData)) ?? []
            polyline = coordinates.compactMap { coord in
                guard let lat = coord["lat"], let lng = coord["lng"] else { return nil }
                return CLLocationCoordinate2D(latitude: lat, longitude: lng)
            }
        }
        
        var instructions: [RouteInstruction] = []
        if let instructionsData = entity.instructionsData as? Data {
            instructions = (try? JSONDecoder().decode([RouteInstruction].self, from: instructionsData)) ?? []
        }
        
        let difficulty = RouteDifficulty(rawValue: entity.difficulty ?? "easy") ?? .easy
        let surface = RouteSurface(rawValue: entity.surface ?? "mixed") ?? .mixed
        let bikeType = BikeType(rawValue: entity.bikeType ?? "city") ?? .city
        
        return BikeRoute(
            startLocation: startLocation,
            endLocation: endLocation,
            waypoints: [], // Waypoints not stored in current model
            distance: entity.distance,
            duration: entity.duration,
            elevation: elevation,
            instructions: instructions,
            polyline: polyline,
            difficulty: difficulty,
            surface: surface,
            bikeType: bikeType,
            createdAt: entity.createdAt ?? Date(),
            isFavorite: entity.isFavorite
        )
    }
    
    private func generateRouteName(for route: BikeRoute) -> String {
        let distance = route.formattedDistance
        let duration = route.formattedDuration
        
        return "Route \(distance) • \(duration)"
    }
    
    private func loadSavedRoutes() {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<BikeRouteEntity> = BikeRouteEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \BikeRouteEntity.createdAt, ascending: false)]
        
        // MEMORY OPTIMIZATION: Limit to 50 most recent routes to prevent memory issues
        fetchRequest.fetchLimit = 50
        
        do {
            savedRoutes = try context.fetch(fetchRequest)
            print("ℹ️ CoreData: Loaded \(savedRoutes.count) routes (limited to prevent memory issues)")
        } catch {
            print("Failed to load saved routes: \(error.localizedDescription)")
            savedRoutes = []
        }
    }
    
    func clearAllData() {
        let context = container.viewContext
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = BikeRouteEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            // Don't reload routes after clearing - they should stay empty
            savedRoutes = []
            print("🗑️ CoreData: Cleared all data and reset savedRoutes array")
            
            // Also clear RouteManager routes to prevent inconsistency
            DispatchQueue.main.async {
                RouteManager.shared.clearRoutes()
                print("🗑️ CoreData: Also cleared RouteManager routes")
            }
        } catch {
            print("Failed to clear data: \(error.localizedDescription)")
        }
    }
    
    func resetPersistentStore() {
        // Remove the SQLite store file(s) completely
        guard let storeDescription = container.persistentStoreDescriptions.first,
              let storeURL = storeDescription.url else {
            clearAllData()
            return
        }
        
        let coordinator = container.persistentStoreCoordinator
        if let store = coordinator.persistentStores.first {
            do {
                try coordinator.remove(store)
            } catch {
                print("Failed to remove persistent store: \(error)")
            }
        }
        
        // Delete files: main, -shm, -wal
        let fileManager = FileManager.default
        let shmURL = storeURL.appendingPathExtension("-shm")
        let walURL = storeURL.appendingPathExtension("-wal")
        try? fileManager.removeItem(at: storeURL)
        try? fileManager.removeItem(at: shmURL)
        try? fileManager.removeItem(at: walURL)
        
        // Reload store clean
        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ CoreData: Failed to reload store after reset: \(error.localizedDescription)")
            } else {
                print("✅ CoreData: Persistent store reset successfully")
                self.loadSavedRoutes()
            }
        }
    }
    
    func exportRoutes() -> Data? {
        let routes = savedRoutes.compactMap { convertToBikeRoute($0) }
        return try? JSONEncoder().encode(routes)
    }
    
    func importRoutes(from data: Data) {
        guard let routes = try? JSONDecoder().decode([BikeRoute].self, from: data) else {
            print("Failed to decode imported routes")
            return
        }
        
        for route in routes {
            saveRoute(route)
        }
    }
}
