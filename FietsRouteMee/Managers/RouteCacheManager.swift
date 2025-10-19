//
//  RouteCacheManager.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 08/10/2025.
//

import Foundation
import CoreLocation
import Combine

class RouteCacheManager: ObservableObject {
    @Published var cachedRoutes: [CachedRoute] = []
    
    private let cacheKey = "cached_routes"
    private let maxCacheSize = 10 // Reduced from 50 to prevent memory issues
    
    init() {
        loadCachedRoutes()
    }
    
    func cacheRoute(_ route: BikeRoute, for request: RouteRequest) {
        let cachedRoute = CachedRoute(
            route: route,
            request: request,
            cachedAt: Date()
        )
        
        cachedRoutes.append(cachedRoute)
        
        // Remove oldest routes if cache is full
        if cachedRoutes.count > maxCacheSize {
            cachedRoutes.removeFirst(cachedRoutes.count - maxCacheSize)
        }
        
        saveCachedRoutes()
    }
    
    func getCachedRoute(for request: RouteRequest) -> BikeRoute? {
        // Find the most recent cached route that matches the request
        let matchingRoutes = cachedRoutes.filter { cachedRoute in
            isRequestMatch(cachedRoute.request, newRequest: request)
        }
        
        return matchingRoutes.last?.route
    }
    
    func clearCache() {
        cachedRoutes.removeAll()
        saveCachedRoutes()
    }
    
    func clearAllCaches() {
        // Clear in-memory and persisted caches
        cachedRoutes.removeAll()
        UserDefaults.standard.removeObject(forKey: cacheKey)
    }
    
    private func isRequestMatch(_ cachedRequest: RouteRequest, newRequest: RouteRequest) -> Bool {
        let distanceThreshold: Double = 1000 // 1km
        let timeThreshold: TimeInterval = 24 * 60 * 60 // 24 hours
        
        // Check if cached route is not too old (simplified check)
        let timeDifference: TimeInterval = Date().timeIntervalSince(cachedRequest.timestamp)
        guard timeDifference < timeThreshold else {
            return false
        }
        
        // Check if start/end points are close enough
        let startDistance = cachedRequest.start.distanceTo(newRequest.start)
        let endDistance = cachedRequest.end.distanceTo(newRequest.end)
        
        return startDistance < distanceThreshold && endDistance < distanceThreshold
    }
    
    private func cleanupOldCache() {
        let cutoffDate = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
        cachedRoutes.removeAll { $0.cachedAt < cutoffDate }
        saveCachedRoutes()
    }
    
    private func saveCachedRoutes() {
        // NOTE: Routes are NOT saved to UserDefaults to prevent memory issues
        // Cache is in-memory only to avoid storing large polyline data
        // This prevents app crashes due to excessive memory usage
        print("ℹ️ RouteCache: Routes kept in memory only (not persisted)")
    }
    
    private func loadCachedRoutes() {
        // NOTE: Routes are NOT loaded from UserDefaults
        // Starting with empty cache each session to prevent memory issues
        cachedRoutes = []
        print("ℹ️ RouteCache: Starting with clean cache")
    }
}

struct CachedRoute: Codable {
    let route: BikeRoute
    let request: RouteRequest
    let cachedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case route, request, cachedAt
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(route, forKey: .route)
        try container.encode(request, forKey: .request)
        try container.encode(cachedAt, forKey: .cachedAt)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.route = try container.decode(BikeRoute.self, forKey: .route)
        self.request = try container.decode(RouteRequest.self, forKey: .request)
        self.cachedAt = try container.decode(Date.self, forKey: .cachedAt)
    }
    
    init(route: BikeRoute, request: RouteRequest, cachedAt: Date) {
        self.route = route
        self.request = request
        self.cachedAt = cachedAt
    }
}