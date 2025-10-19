//
//  OfflineNavigationManager.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 08/10/2025.
//

import Foundation
import CoreLocation
import MapKit
import Combine

class OfflineNavigationManager: NSObject, ObservableObject {
    @Published var isNavigating = false
    @Published var currentRoute: BikeRoute?
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var currentInstruction: RouteInstruction?
    @Published var distanceToNextTurn: Double = 0
    @Published var estimatedTimeToDestination: TimeInterval = 0
    @Published var navigationProgress: Double = 0
    
    private let locationManager = CLLocationManager()
    private let voiceManager = VoiceNavigationManager.shared
    @Published var routeInstructions: [RouteInstruction] = []
    @Published var currentInstructionIndex = 0
    private var cancellables = Set<AnyCancellable>()
    private var lastSpokenDistance: Double = 0
    
    override init() {
        super.init()
        setupLocationManager()
        requestLocationPermission()
    }
    
    private func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("Location access denied")
        @unknown default:
            break
        }
    }
    
    func startNavigation(for route: BikeRoute) {
        guard !isNavigating else { return }
        
        currentRoute = route
        routeInstructions = route.instructions
        currentInstructionIndex = 0
        isNavigating = true
        
        // Start location updates for real-time navigation
        locationManager.startUpdatingLocation()
        
        // Speak route start
        voiceManager.speakRouteStart()
        
        updateCurrentInstruction()
        updateNavigationMetrics()
    }
    
    func stopNavigation() {
        isNavigating = false
        currentRoute = nil
        currentInstruction = nil
        routeInstructions = []
        currentInstructionIndex = 0
        distanceToNextTurn = 0
        estimatedTimeToDestination = 0
        navigationProgress = 0
        
        // Stop location updates
        locationManager.stopUpdatingLocation()
        
        // Stop any ongoing speech
        voiceManager.stopSpeaking()
    }
    
    func nextInstruction() {
        guard currentInstructionIndex < routeInstructions.count - 1 else { return }
        
        currentInstructionIndex += 1
        updateCurrentInstruction()
        updateNavigationMetrics()
        
        // Speak the new instruction
        if let instruction = currentInstruction {
            voiceManager.speakTurnInstruction(instruction, distance: distanceToNextTurn)
        }
    }
    
    func previousInstruction() {
        guard currentInstructionIndex > 0 else { return }
        
        currentInstructionIndex -= 1
        updateCurrentInstruction()
        updateNavigationMetrics()
        
        // Speak the instruction
        if let instruction = currentInstruction {
            voiceManager.speakTurnInstruction(instruction, distance: distanceToNextTurn)
        }
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters (reduced frequency)
        locationManager.activityType = .fitness // Optimize for cycling
        locationManager.pausesLocationUpdatesAutomatically = true // Save battery
    }
    
    private func updateCurrentInstruction() {
        guard currentInstructionIndex < routeInstructions.count else { return }
        
        currentInstruction = routeInstructions[currentInstructionIndex]
        
        // Calculate distance to next turn
        if let currentLocation = currentLocation,
           let instruction = currentInstruction {
            distanceToNextTurn = currentLocation.distanceTo(instruction.coordinate)
        }
        
        // Calculate navigation progress
        if let route = currentRoute {
            let totalDistance = route.distance
            let remainingDistance = calculateRemainingDistance()
            navigationProgress = max(0, min(1, (totalDistance - remainingDistance) / totalDistance))
        }
        
        // Calculate estimated time to destination
        estimatedTimeToDestination = calculateEstimatedTimeToDestination()
    }
    
    private func calculateRemainingDistance() -> Double {
        guard let currentLocation = currentLocation,
              let route = currentRoute else { return 0 }
        
        // Calculate distance from current location to destination
        return currentLocation.distanceTo(route.endLocation)
    }
    
    private func calculateEstimatedTimeToDestination() -> TimeInterval {
        guard let route = currentRoute else { return 0 }
        
        let remainingDistance = calculateRemainingDistance()
        let averageSpeed = route.averageSpeed / 3.6 // Convert km/h to m/s
        return remainingDistance / averageSpeed
    }
    
    private func checkForInstructionUpdate() {
        guard let currentLocation = currentLocation,
              let instruction = currentInstruction else { return }
        
        let distanceToInstruction = currentLocation.distanceTo(instruction.coordinate)
        
        // Speak distance updates
        if shouldSpeakDistanceUpdate(distanceToInstruction) {
            voiceManager.speakDistanceUpdate(distanceToInstruction)
            lastSpokenDistance = distanceToInstruction
        }
        
        // If we're close to the current instruction, move to next one
        if distanceToInstruction < 50 { // 50 meters threshold
            nextInstruction()
        }
        
        // Check if we've arrived at destination
        if let _ = currentRoute, distanceToInstruction < 20 && instruction.type == .destination {
            voiceManager.speakArrival()
        }
    }
    
    private func shouldSpeakDistanceUpdate(_ distance: Double) -> Bool {
        // Speak at specific intervals: 1000m, 500m, 200m, 100m, 50m
        let speakDistances: [Double] = [1000, 500, 200, 100, 50]
        
        for speakDistance in speakDistances {
            if distance <= speakDistance && lastSpokenDistance > speakDistance {
                return true
            }
        }
        
        return false
    }
    
    private func checkForUpcomingTurns() {
        guard let currentLocation = currentLocation,
              let instruction = currentInstruction else { return }
        
        let distanceToTurn = currentLocation.distanceTo(instruction.coordinate)
        
        // Speak distance updates at specific intervals
        if distanceToTurn <= 200 && lastSpokenDistance > 200 {
            voiceManager.speakDistanceUpdate(distanceToTurn)
            lastSpokenDistance = distanceToTurn
        } else if distanceToTurn <= 50 && lastSpokenDistance > 50 {
            voiceManager.speakDistanceUpdate(distanceToTurn)
            lastSpokenDistance = distanceToTurn
        }
        
        // Auto-advance to next instruction when close to turn
        if distanceToTurn <= 30 && currentInstructionIndex < routeInstructions.count - 1 {
            nextInstruction()
        }
    }
    
    private func checkForArrival() {
        guard let currentLocation = currentLocation,
              let route = currentRoute else { return }
        
        let distanceToDestination = currentLocation.distanceTo(route.endLocation)
        
        if distanceToDestination <= 50 {
            voiceManager.speakArrival()
            stopNavigation()
        }
    }
    
    private func updateNavigationMetrics() {
        guard let route = currentRoute,
              let _ = currentLocation else { return }
        
        // Calculate progress
        let totalDistance = route.distance
        let remainingDistance = calculateRemainingDistance()
        navigationProgress = max(0, min(1, (totalDistance - remainingDistance) / totalDistance))
        
        // Calculate estimated time to destination
        let averageSpeed: Double = 18.0 // km/h
        estimatedTimeToDestination = (remainingDistance / 1000) / averageSpeed * 3600 // Convert to seconds
    }
}

// MARK: - CLLocationManagerDelegate
extension OfflineNavigationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location.coordinate
            
            if self.isNavigating {
                self.updateCurrentInstruction()
                self.updateNavigationMetrics()
                self.checkForUpcomingTurns()
                self.checkForArrival()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
    }
}

