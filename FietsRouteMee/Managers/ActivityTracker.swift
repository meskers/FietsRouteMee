//
//  ActivityTracker.swift
//  FietsRouteMee
//
//  Strava-style Activity Tracking Manager
//

import Foundation
import CoreLocation
import Combine

@MainActor
class ActivityTracker: NSObject, ObservableObject {
    static let shared = ActivityTracker()
    
    @Published var currentActivity: CyclingActivity?
    @Published var activities: [CyclingActivity] = []
    @Published var isTracking = false
    @Published var isPaused = false
    @Published var statistics = ActivityStatistics()
    
    private var locationManager: CLLocationManager!
    private var lastLocation: CLLocation?
    private var pauseStartTime: Date?
    private var activityStartTime: Date?
    
    private let activitiesKey = "cycling_activities"
    private let userDefaults = UserDefaults.standard
    
    private override init() {
        super.init()
        setupLocationManager()
        loadActivities()
        calculateStatistics()
    }
    
    // MARK: - Location Manager Setup
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // Update every 5 meters
        locationManager.activityType = .fitness
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    // MARK: - Activity Control
    
    func startActivity(name: String = "Cycling", bikeType: BikeType = .city) {
        guard !isTracking else {
            print("⚠️ Activity already in progress")
            return
        }
        
        let activity = CyclingActivity(name: name, startDate: Date(), bikeType: bikeType)
        currentActivity = activity
        activityStartTime = Date()
        isTracking = true
        isPaused = false
        lastLocation = nil
        
        locationManager.startUpdatingLocation()
        
        print("🚴‍♂️ Started activity: \(name)")
    }
    
    func pauseActivity() {
        guard isTracking, !isPaused else { return }
        
        isPaused = true
        pauseStartTime = Date()
        locationManager.stopUpdatingLocation()
        
        print("⏸️ Activity paused")
    }
    
    func resumeActivity() {
        guard isTracking, isPaused else { return }
        
        if let pauseStart = pauseStartTime {
            let pauseDuration = Date().timeIntervalSince(pauseStart)
            currentActivity?.pausedDuration += pauseDuration
        }
        
        isPaused = false
        pauseStartTime = nil
        locationManager.startUpdatingLocation()
        
        print("▶️ Activity resumed")
    }
    
    func stopActivity() {
        guard isTracking else { return }
        
        locationManager.stopUpdatingLocation()
        
        if var activity = currentActivity {
            activity.endDate = Date()
            
            // Calculate final metrics
            if let startTime = activityStartTime {
                activity.duration = Date().timeIntervalSince(startTime)
            }
            
            // Calculate average speed
            if activity.movingTime > 0 {
                activity.avgSpeed = (activity.distance / activity.movingTime) * 3.6 // m/s to km/h
            }
            
            // Calculate calories (rough estimate: 8 kcal per km for cycling)
            activity.calories = (activity.distance / 1000.0) * 8.0
            
            activities.insert(activity, at: 0) // Add to beginning
            saveActivities()
            calculateStatistics()
            
            print("✅ Activity stopped and saved")
            print("   Distance: \(activity.formattedDistance)")
            print("   Duration: \(activity.formattedDuration)")
            print("   Avg Speed: \(activity.formattedAvgSpeed)")
        }
        
        currentActivity = nil
        isTracking = false
        isPaused = false
        lastLocation = nil
        activityStartTime = nil
    }
    
    func deleteActivity(_ activity: CyclingActivity) {
        activities.removeAll { $0.id == activity.id }
        saveActivities()
        calculateStatistics()
        print("🗑️ Deleted activity: \(activity.name)")
    }
    
    // MARK: - Statistics
    
    private func calculateStatistics() {
        var stats = ActivityStatistics()
        stats.totalActivities = activities.count
        
        for activity in activities {
            stats.totalDistance += activity.distance
            stats.totalDuration += activity.duration
            stats.totalElevation += activity.elevationGain
            stats.totalCalories += activity.calories
        }
        
        if stats.totalDuration > 0 {
            stats.avgSpeed = (stats.totalDistance / stats.totalDuration) * 3.6
        }
        
        statistics = stats
    }
    
    // MARK: - Export
    
    func exportToGPX(activity: CyclingActivity) -> String {
        var gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="FietsRouteMee">
          <metadata>
            <name>\(activity.name)</name>
            <time>\(ISO8601DateFormatter().string(from: activity.startDate))</time>
          </metadata>
          <trk>
            <name>\(activity.name)</name>
            <type>cycling</type>
            <trkseg>
        
        """
        
        for point in activity.trackPoints {
            let timestamp = ISO8601DateFormatter().string(from: point.timestamp)
            gpx += """
                  <trkpt lat="\(point.coordinate.latitude)" lon="\(point.coordinate.longitude)">
                    <ele>\(point.elevation)</ele>
                    <time>\(timestamp)</time>
                  </trkpt>
            
            """
        }
        
        gpx += """
            </trkseg>
          </trk>
        </gpx>
        """
        
        print("📤 Exported activity to GPX: \(activity.name)")
        return gpx
    }
    
    // MARK: - Persistence
    
    private func saveActivities() {
        do {
            // Only save the most recent 100 activities to prevent memory issues
            let activitiesToSave = Array(activities.prefix(100))
            let data = try JSONEncoder().encode(activitiesToSave)
            userDefaults.set(data, forKey: activitiesKey)
            print("ℹ️ Saved \(activitiesToSave.count) activities")
        } catch {
            print("❌ Failed to save activities: \(error)")
        }
    }
    
    private func loadActivities() {
        guard let data = userDefaults.data(forKey: activitiesKey) else {
            print("ℹ️ No saved activities found")
            return
        }
        
        do {
            activities = try JSONDecoder().decode([CyclingActivity].self, from: data)
            print("✅ Loaded \(activities.count) activities")
        } catch {
            print("❌ Failed to load activities: \(error)")
            activities = []
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension ActivityTracker: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last, isTracking, !isPaused else { return }
            
            // MEMORY OPTIMIZATION: Only add trackpoint if moved enough or every 10 points
            let shouldAddPoint: Bool
            if let last = lastLocation {
                let distance = location.distance(from: last)
                shouldAddPoint = distance > 10 || (currentActivity?.trackPoints.count ?? 0) % 10 == 0
            } else {
                shouldAddPoint = true
            }
            
            if shouldAddPoint {
                // Create track point
                let trackPoint = TrackPoint(
                    coordinate: location.coordinate,
                    elevation: location.altitude,
                    timestamp: location.timestamp,
                    speed: location.speed
                )
                
                currentActivity?.trackPoints.append(trackPoint)
                
                // MEMORY OPTIMIZATION: Limit trackpoints to prevent memory issues
                if let count = currentActivity?.trackPoints.count, count > 1000 {
                    // Keep only every 2nd point for older data
                    currentActivity?.trackPoints = currentActivity?.trackPoints.enumerated()
                        .filter { index, _ in index % 2 == 0 || index >= count - 500 }
                        .map { $0.element } ?? []
                    print("⚠️ Activity: Reduced trackpoints to prevent memory issues")
                }
            }
            
            // Calculate distance from last location
            if let last = lastLocation {
                let distance = location.distance(from: last)
                currentActivity?.distance += distance
                
                // Update max speed
                let speedKmH = location.speed * 3.6 // m/s to km/h
                if speedKmH > (currentActivity?.maxSpeed ?? 0) {
                    currentActivity?.maxSpeed = speedKmH
                }
                
                // Calculate elevation gain
                let elevationDiff = location.altitude - last.altitude
                if elevationDiff > 0 {
                    currentActivity?.elevationGain += elevationDiff
                }
            }
            
            lastLocation = location
            
            // Update duration
            if let startTime = activityStartTime {
                currentActivity?.duration = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error.localizedDescription)")
    }
}

