//
//  AppSettingsManager.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 10/10/2025.
//

import Foundation
import AVFoundation
import CoreLocation
import Combine
import MapKit

class AppSettingsManager: ObservableObject {
    // MARK: - Singleton
    static let shared = AppSettingsManager()
    
    // MARK: - Voice Settings
    @Published var isVoiceEnabled: Bool {
        didSet { UserDefaults.standard.set(isVoiceEnabled, forKey: "voice_enabled") }
    }
    
    @Published var voiceVolume: Float {
        didSet { UserDefaults.standard.set(voiceVolume, forKey: "voice_volume") }
    }
    
    @Published var voiceSpeed: Float {
        didSet { UserDefaults.standard.set(voiceSpeed, forKey: "voice_speed") }
    }
    
    @Published var voiceLanguage: String {
        didSet { UserDefaults.standard.set(voiceLanguage, forKey: "voice_language") }
    }
    
    // MARK: - Map Settings
    @Published var mapType: MapType {
        didSet { UserDefaults.standard.set(mapType.rawValue, forKey: "map_type") }
    }
    
    @Published var showsTraffic: Bool {
        didSet { UserDefaults.standard.set(showsTraffic, forKey: "shows_traffic") }
    }
    
    @Published var showsBuildings: Bool {
        didSet { UserDefaults.standard.set(showsBuildings, forKey: "shows_buildings") }
    }
    
    @Published var showsCompass: Bool {
        didSet { UserDefaults.standard.set(showsCompass, forKey: "shows_compass") }
    }
    
    @Published var showsScale: Bool {
        didSet { UserDefaults.standard.set(showsScale, forKey: "shows_scale") }
    }
    
    @Published var showKnooppunten: Bool {
        didSet { UserDefaults.standard.set(showKnooppunten, forKey: "show_knooppunten") }
    }
    
    @Published var showCyclingPOIs: Bool {
        didSet { UserDefaults.standard.set(showCyclingPOIs, forKey: "show_cycling_pois") }
    }
    
    @Published var useOfflineRouting: Bool {
        didSet { UserDefaults.standard.set(useOfflineRouting, forKey: "use_offline_routing") }
    }
    
    @Published var mapLibreEnabled: Bool {
        didSet { UserDefaults.standard.set(mapLibreEnabled, forKey: "maplibre_enabled") }
    }
    
    // MARK: - Route Settings
    @Published var selectedBikeType: BikeType {
        didSet { 
            UserDefaults.standard.set(selectedBikeType.rawValue, forKey: "selected_bike_type")
            print("🚴‍♂️ AppSettings: Bike type changed to \(selectedBikeType.displayName)")
        }
    }
    
    @Published var avoidHighways: Bool {
        didSet { UserDefaults.standard.set(avoidHighways, forKey: "avoid_highways") }
    }
    
    @Published var avoidTunnels: Bool {
        didSet { UserDefaults.standard.set(avoidTunnels, forKey: "avoid_tunnels") }
    }
    
    @Published var preferBikePaths: Bool {
        didSet { UserDefaults.standard.set(preferBikePaths, forKey: "prefer_bike_paths") }
    }
    
    @Published var preferNature: Bool {
        didSet { UserDefaults.standard.set(preferNature, forKey: "prefer_nature") }
    }
    
    @Published var maxDistance: Double {
        didSet { UserDefaults.standard.set(maxDistance, forKey: "max_distance") }
    }
    
    @Published var maxElevation: Double {
        didSet { UserDefaults.standard.set(maxElevation, forKey: "max_elevation") }
    }
    
    // MARK: - Privacy Settings
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    
    enum MapType: String, CaseIterable {
        case standard = "standard"
        case satellite = "satellite"
        case hybrid = "hybrid"
        
        var displayName: String {
            switch self {
            case .standard: return "Standaard"
            case .satellite: return "Satelliet"
            case .hybrid: return "Hybride"
            }
        }
        
        var mapKitType: MKMapType {
            switch self {
            case .standard: return .standard
            case .satellite: return .satellite
            case .hybrid: return .hybrid
            }
        }
    }
    
    private init() {
        // Load saved settings or use defaults
        self.isVoiceEnabled = UserDefaults.standard.object(forKey: "voice_enabled") as? Bool ?? true
        self.voiceVolume = UserDefaults.standard.object(forKey: "voice_volume") as? Float ?? 0.8
        self.voiceSpeed = UserDefaults.standard.object(forKey: "voice_speed") as? Float ?? 0.5
        self.voiceLanguage = UserDefaults.standard.string(forKey: "voice_language") ?? "nl-NL"
        
        let mapTypeRaw = UserDefaults.standard.string(forKey: "map_type") ?? MapType.standard.rawValue
        self.mapType = MapType(rawValue: mapTypeRaw) ?? .standard
        self.showsTraffic = UserDefaults.standard.object(forKey: "shows_traffic") as? Bool ?? false
        self.showsBuildings = UserDefaults.standard.object(forKey: "shows_buildings") as? Bool ?? true
        self.showsCompass = UserDefaults.standard.object(forKey: "shows_compass") as? Bool ?? true
        self.showsScale = UserDefaults.standard.object(forKey: "shows_scale") as? Bool ?? true
        self.showKnooppunten = UserDefaults.standard.object(forKey: "show_knooppunten") as? Bool ?? true
        self.showCyclingPOIs = UserDefaults.standard.object(forKey: "show_cycling_pois") as? Bool ?? true
        self.useOfflineRouting = UserDefaults.standard.object(forKey: "use_offline_routing") as? Bool ?? false
        self.mapLibreEnabled = UserDefaults.standard.object(forKey: "maplibre_enabled") as? Bool ?? true
        
        // Load route settings
        let bikeTypeRaw = UserDefaults.standard.string(forKey: "selected_bike_type") ?? BikeType.city.rawValue
        self.selectedBikeType = BikeType(rawValue: bikeTypeRaw) ?? .city
        self.avoidHighways = UserDefaults.standard.object(forKey: "avoid_highways") as? Bool ?? true
        self.avoidTunnels = UserDefaults.standard.object(forKey: "avoid_tunnels") as? Bool ?? false
        self.preferBikePaths = UserDefaults.standard.object(forKey: "prefer_bike_paths") as? Bool ?? true
        self.preferNature = UserDefaults.standard.object(forKey: "prefer_nature") as? Bool ?? false
        self.maxDistance = UserDefaults.standard.object(forKey: "max_distance") as? Double ?? 50.0
        self.maxElevation = UserDefaults.standard.object(forKey: "max_elevation") as? Double ?? 200.0
        
        // Check permissions
        checkPermissions()
    }
    
    func checkPermissions() {
        // Use the shared LocationManager to avoid creating multiple instances
        Task { @MainActor in
            locationPermissionStatus = LocationManager.shared.authorizationStatus
        }
    }
    
    func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    func getRoutePreferences() -> RoutePreferences {
        return RoutePreferences(
            avoidHighways: avoidHighways,
            avoidTunnels: avoidTunnels,
            preferBikePaths: preferBikePaths,
            preferNature: preferNature,
            maxDistance: maxDistance,
            maxElevation: maxElevation
        )
    }
    
    func resetToDefaults() {
        isVoiceEnabled = true
        voiceVolume = 0.8
        voiceSpeed = 0.5
        voiceLanguage = "nl-NL"
        
        mapType = .standard
        showsTraffic = false
        showsBuildings = true
        showsCompass = true
        showsScale = true
        showKnooppunten = true
        showCyclingPOIs = true
        useOfflineRouting = false
        mapLibreEnabled = true
        
        // Clear UserDefaults
        let keys = ["voice_enabled", "voice_volume", "voice_speed", "voice_language",
                   "map_type", "shows_traffic", "shows_buildings", "shows_compass", "shows_scale",
                   "show_knooppunten", "show_cycling_pois", "use_offline_routing", "maplibre_enabled"]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    var availableVoices: [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices().filter { voice in
            voice.language.hasPrefix("nl") || voice.language.hasPrefix("en")
        }
    }
    
    var currentVoice: AVSpeechSynthesisVoice? {
        return AVSpeechSynthesisVoice(language: voiceLanguage)
    }
}

// MARK: - Extensions for Permission Descriptions
extension CLAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: return "Niet bepaald"
        case .restricted: return "Beperkt"
        case .denied: return "Geweigerd"
        case .authorizedAlways: return "Altijd toegestaan"
        case .authorizedWhenInUse: return "Bij gebruik toegestaan"
        case .authorized: return "Toegestaan"
        @unknown default: return "Onbekend"
        }
    }
}
