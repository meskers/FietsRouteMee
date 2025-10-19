//
//  SegmentManager.swift
//  FietsRouteMee
//
//  Strava-style Segment Tracking Manager
//

import Foundation
import CoreLocation
import Combine

@MainActor
class SegmentManager: ObservableObject {
    static let shared = SegmentManager()
    
    @Published var segments: [Segment] = []
    @Published var myEfforts: [SegmentEffort] = []
    
    private let segmentsKey = "cycling_segments"
    private let effortsKey = "segment_efforts"
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadSegments()
        loadEfforts()
        if segments.isEmpty {
            createDefaultSegments()
        }
    }
    
    // MARK: - Segment Management
    
    func createSegment(_ segment: Segment) {
        segments.append(segment)
        saveSegments()
        print("✅ Segment: Created '\(segment.name)'")
    }
    
    func deleteSegment(_ segment: Segment) {
        segments.removeAll { $0.id == segment.id }
        saveSegments()
        print("🗑️ Segment: Deleted '\(segment.name)'")
    }
    
    func recordEffort(_ effort: SegmentEffort) {
        myEfforts.append(effort)
        
        // Update segment's personal best
        if let segmentIndex = segments.firstIndex(where: { $0.id == effort.segmentID }) {
            segments[segmentIndex].attempts += 1
            
            if let currentPB = segments[segmentIndex].personalBest {
                if effort.duration < currentPB.duration {
                    segments[segmentIndex].personalBest = effort
                    print("🎉 NEW PERSONAL BEST on '\(segments[segmentIndex].name)'!")
                }
            } else {
                segments[segmentIndex].personalBest = effort
                print("🎉 FIRST EFFORT on '\(segments[segmentIndex].name)'!")
            }
            
            // Add to leaderboard (keep top 10)
            segments[segmentIndex].leaderboard.append(effort)
            segments[segmentIndex].leaderboard.sort { $0.duration < $1.duration }
            segments[segmentIndex].leaderboard = Array(segments[segmentIndex].leaderboard.prefix(10))
        }
        
        saveSegments()
        saveEfforts()
        print("✅ Segment: Recorded effort on segment")
    }
    
    // MARK: - Search & Filter
    
    func findNearbySegments(to coordinate: CLLocationCoordinate2D, radius: Double = 10000) -> [Segment] {
        return segments.filter { segment in
            segment.startCoordinate.distanceTo(coordinate) <= radius ||
            segment.endCoordinate.distanceTo(coordinate) <= radius
        }.sorted { seg1, seg2 in
            let dist1 = min(seg1.startCoordinate.distanceTo(coordinate), seg1.endCoordinate.distanceTo(coordinate))
            let dist2 = min(seg2.startCoordinate.distanceTo(coordinate), seg2.endCoordinate.distanceTo(coordinate))
            return dist1 < dist2
        }
    }
    
    func getSegments(by difficulty: SegmentDifficulty) -> [Segment] {
        return segments.filter { $0.difficulty == difficulty }
    }
    
    func getKOMSegments() -> [Segment] {
        // Get segments where user has the best time
        return segments.filter { segment in
            guard let pb = segment.personalBest else { return false }
            return segment.leaderboard.first?.id == pb.id
        }
    }
    
    // MARK: - Persistence
    
    private func saveSegments() {
        do {
            let data = try JSONEncoder().encode(segments)
            userDefaults.set(data, forKey: segmentsKey)
            print("ℹ️ Segment: Saved \(segments.count) segments")
        } catch {
            print("❌ Segment: Failed to save: \(error)")
        }
    }
    
    private func loadSegments() {
        guard let data = userDefaults.data(forKey: segmentsKey) else {
            print("ℹ️ Segment: No saved segments found")
            return
        }
        
        do {
            segments = try JSONDecoder().decode([Segment].self, from: data)
            print("✅ Segment: Loaded \(segments.count) segments")
        } catch {
            print("❌ Segment: Failed to load: \(error)")
            segments = []
        }
    }
    
    private func saveEfforts() {
        do {
            // Keep only last 100 efforts to prevent memory issues
            let effortsToSave = Array(myEfforts.suffix(100))
            let data = try JSONEncoder().encode(effortsToSave)
            userDefaults.set(data, forKey: effortsKey)
            print("ℹ️ Segment: Saved \(effortsToSave.count) efforts")
        } catch {
            print("❌ Segment: Failed to save efforts: \(error)")
        }
    }
    
    private func loadEfforts() {
        guard let data = userDefaults.data(forKey: effortsKey) else {
            print("ℹ️ Segment: No saved efforts found")
            return
        }
        
        do {
            myEfforts = try JSONDecoder().decode([SegmentEffort].self, from: data)
            print("✅ Segment: Loaded \(myEfforts.count) efforts")
        } catch {
            print("❌ Segment: Failed to load efforts: \(error)")
            myEfforts = []
        }
    }
    
    // MARK: - Default Segments (Famous Dutch cycling segments)
    
    private func createDefaultSegments() {
        let defaultSegments: [Segment] = [
            // Amsterdam
            Segment(
                name: "Vondelpark Sprint",
                description: "Snelle sprint door het Vondelpark",
                startCoordinate: CLLocationCoordinate2D(latitude: 52.3579, longitude: 4.8686),
                endCoordinate: CLLocationCoordinate2D(latitude: 52.3608, longitude: 4.8621),
                distance: 850,
                elevationGain: 5,
                averageGrade: 0.6,
                difficulty: .moderate
            ),
            
            // Utrecht
            Segment(
                name: "Domtoren Climb",
                description: "Korte maar intense klim richting Domtoren",
                startCoordinate: CLLocationCoordinate2D(latitude: 52.0897, longitude: 5.1186),
                endCoordinate: CLLocationCoordinate2D(latitude: 52.0908, longitude: 5.1214),
                distance: 320,
                elevationGain: 12,
                averageGrade: 3.8,
                difficulty: .hard
            ),
            
            // Gelderland - Posbank
            Segment(
                name: "Posbank Climb",
                description: "Legendarische Posbank klim, zwaarste in Nederland",
                startCoordinate: CLLocationCoordinate2D(latitude: 52.0198, longitude: 5.9612),
                endCoordinate: CLLocationCoordinate2D(latitude: 52.0234, longitude: 5.9654),
                distance: 1200,
                elevationGain: 75,
                averageGrade: 6.3,
                difficulty: .expert
            ),
            
            // Limburg - Cauberg
            Segment(
                name: "Cauberg",
                description: "Beroemde Amstel Gold Race klim",
                startCoordinate: CLLocationCoordinate2D(latitude: 50.8531, longitude: 5.8142),
                endCoordinate: CLLocationCoordinate2D(latitude: 50.8559, longitude: 5.8198),
                distance: 1200,
                elevationGain: 85,
                averageGrade: 7.1,
                difficulty: .expert
            ),
            
            // Noord-Holland
            Segment(
                name: "Dijk Sprint",
                description: "Vlakke sprint langs de dijk",
                startCoordinate: CLLocationCoordinate2D(latitude: 52.4523, longitude: 4.8976),
                endCoordinate: CLLocationCoordinate2D(latitude: 52.4612, longitude: 4.9123),
                distance: 2100,
                elevationGain: 8,
                averageGrade: 0.4,
                difficulty: .easy
            )
        ]
        
        segments = defaultSegments
        saveSegments()
        print("✅ Segment: Created \(defaultSegments.count) default segments")
    }
    
    func clearAll() {
        segments.removeAll()
        myEfforts.removeAll()
        userDefaults.removeObject(forKey: segmentsKey)
        userDefaults.removeObject(forKey: effortsKey)
        print("ℹ️ Segment: Cleared all segments and efforts")
    }
}

