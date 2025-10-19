//
//  CollectionsManager.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 16/10/2025.
//

import Foundation
import Combine

class CollectionsManager: ObservableObject {
    static let shared = CollectionsManager()
    
    @Published var collections: [RouteCollection] = []
    
    private let collectionsKey = "route_collections"
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadCollections()
        createDefaultCollections()
    }
    
    // MARK: - Collection Management
    
    func createCollection(_ collection: RouteCollection) {
        collections.append(collection)
        saveCollections()
        print("✅ Collections: Created '\(collection.name)'")
    }
    
    func updateCollection(_ collection: RouteCollection) {
        if let index = collections.firstIndex(where: { $0.id == collection.id }) {
            collections[index] = collection
            saveCollections()
            print("✅ Collections: Updated '\(collection.name)'")
        }
    }
    
    func deleteCollection(_ collection: RouteCollection) {
        collections.removeAll { $0.id == collection.id }
        saveCollections()
        print("✅ Collections: Deleted '\(collection.name)'")
    }
    
    func addRouteToCollection(routeID: UUID, collectionID: UUID) {
        if let index = collections.firstIndex(where: { $0.id == collectionID }) {
            if !collections[index].routeIDs.contains(routeID) {
                collections[index].routeIDs.append(routeID)
                saveCollections()
                print("✅ Collections: Added route to '\(collections[index].name)'")
            }
        }
    }
    
    func removeRouteFromCollection(routeID: UUID, collectionID: UUID) {
        if let index = collections.firstIndex(where: { $0.id == collectionID }) {
            collections[index].routeIDs.removeAll { $0 == routeID }
            saveCollections()
            print("✅ Collections: Removed route from '\(collections[index].name)'")
        }
    }
    
    func getCollection(by id: UUID) -> RouteCollection? {
        return collections.first { $0.id == id }
    }
    
    func getCollections(containing routeID: UUID) -> [RouteCollection] {
        return collections.filter { $0.routeIDs.contains(routeID) }
    }
    
    // MARK: - Persistence
    
    private func saveCollections() {
        do {
            // MEMORY OPTIMIZATION: Remove cover images before saving
            var collectionsToSave = collections
            for i in 0..<collectionsToSave.count {
                collectionsToSave[i].coverImageData = nil
            }
            
            let data = try JSONEncoder().encode(collectionsToSave)
            
            // Check data size
            let sizeInMB = Double(data.count) / 1_048_576
            if sizeInMB > 0.5 {
                print("⚠️ Collections: Data too large (\(String(format: "%.2f", sizeInMB))MB)")
            }
            
            userDefaults.set(data, forKey: collectionsKey)
            print("ℹ️ Collections: Saved \(collections.count) collections")
        } catch {
            print("❌ Collections: Failed to save: \(error)")
        }
    }
    
    private func loadCollections() {
        guard let data = userDefaults.data(forKey: collectionsKey) else {
            print("ℹ️ Collections: No saved collections found")
            return
        }
        
        do {
            collections = try JSONDecoder().decode([RouteCollection].self, from: data)
            print("✅ Collections: Loaded \(collections.count) collections")
        } catch {
            print("❌ Collections: Failed to load: \(error)")
            collections = []
        }
    }
    
    // MARK: - Default Collections
    
    private func createDefaultCollections() {
        if collections.isEmpty {
            let favorites = RouteCollection(
                name: "Favorieten",
                description: "Je favoriete routes",
                color: "#FF3B30"
            )
            
            let weekend = RouteCollection(
                name: "Weekend Routes",
                description: "Mooie routes voor het weekend",
                color: "#34C759"
            )
            
            let training = RouteCollection(
                name: "Training",
                description: "Routes voor training",
                color: "#007AFF"
            )
            
            collections = [favorites, weekend, training]
            saveCollections()
            print("✅ Collections: Created default collections")
        }
    }
    
    func clearAll() {
        collections.removeAll()
        userDefaults.removeObject(forKey: collectionsKey)
        print("ℹ️ Collections: Cleared all collections")
    }
}

