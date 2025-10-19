//
//  FavoritesManager.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 08/10/2025.
//

import Foundation
import Combine

class FavoritesManager: ObservableObject {
    @Published var favoriteRoutes: [BikeRoute] = []
    
    private let coreDataManager = CoreDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadFavorites()
        
        // Listen for Core Data changes
        coreDataManager.$savedRoutes
            .sink { [weak self] _ in
                self?.loadFavorites()
            }
            .store(in: &cancellables)
    }
    
    func toggleFavorite(_ route: BikeRoute) {
        // Save route to Core Data first if not already saved
        coreDataManager.saveRoute(route)
        
        // Toggle favorite status
        coreDataManager.toggleFavorite(route)
    }
    
    func isFavorite(_ route: BikeRoute) -> Bool {
        return favoriteRoutes.contains { $0.id == route.id }
    }
    
    func addFavorite(_ route: BikeRoute) {
        coreDataManager.saveRoute(route)
        coreDataManager.toggleFavorite(route)
    }
    
    func removeFavorite(_ route: BikeRoute) {
        coreDataManager.toggleFavorite(route)
    }
    
    func clearAllFavorites() {
        for route in favoriteRoutes {
            coreDataManager.toggleFavorite(route)
        }
    }
    
    private func loadFavorites() {
        favoriteRoutes = coreDataManager.getFavoriteRoutes()
    }
    
    func getFavoriteCount() -> Int {
        return favoriteRoutes.count
    }
    
    func getTotalDistance() -> Double {
        return favoriteRoutes.reduce(0) { $0 + $1.distance }
    }
    
    func getTotalDuration() -> TimeInterval {
        return favoriteRoutes.reduce(0) { $0 + $1.duration }
    }
}
