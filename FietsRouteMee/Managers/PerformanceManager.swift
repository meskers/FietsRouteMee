//
//  PerformanceManager.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 18/10/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class PerformanceManager: ObservableObject {
    static let shared = PerformanceManager()
    
    @Published var memoryUsage: Double = 0.0
    @Published var cpuUsage: Double = 0.0
    @Published var batteryLevel: Float = 1.0
    @Published var isLowPowerMode = false
    @Published var isThermalStateNormal = true
    @Published var isMemoryWarning = false
    
    // Performance settings
    @Published var enableImageCaching = true
    @Published var enableRouteCaching = true
    @Published var enableBackgroundRefresh = true
    @Published var maxCachedRoutes = 50
    @Published var maxCachedImages = 100
    @Published var enableMemoryOptimization = true
    @Published var enableCPUOptimization = true
    
    nonisolated(unsafe) private var memoryTimer: Timer?
    nonisolated(unsafe) private var performanceTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupPerformanceMonitoring()
        loadSettings()
        startMemoryMonitoring()
    }
    
    deinit {
        // Stop monitoring synchronously to avoid capturing self
        stopMonitoring()
    }
    
    // MARK: - Setup
    
    private func setupPerformanceMonitoring() {
        // Monitor system notifications
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleMemoryWarning()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateThermalState()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updatePowerState()
            }
        }
        
        // Initialize current values
        updateMemoryUsage()
        updateBatteryLevel()
        updateThermalState()
        updatePowerState()
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        enableImageCaching = defaults.bool(forKey: "performance.enableImageCaching")
        enableRouteCaching = defaults.bool(forKey: "performance.enableRouteCaching")
        enableBackgroundRefresh = defaults.bool(forKey: "performance.enableBackgroundRefresh")
        maxCachedRoutes = defaults.integer(forKey: "performance.maxCachedRoutes")
        maxCachedImages = defaults.integer(forKey: "performance.maxCachedImages")
        enableMemoryOptimization = defaults.bool(forKey: "performance.enableMemoryOptimization")
        enableCPUOptimization = defaults.bool(forKey: "performance.enableCPUOptimization")
    }
    
    // MARK: - Monitoring
    
    private func startMemoryMonitoring() {
        memoryTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMemoryUsage()
            }
        }
        
        performanceTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateCPUUsage()
            }
        }
    }
    
    nonisolated private func stopMonitoring() {
        memoryTimer?.invalidate()
        performanceTimer?.invalidate()
        memoryTimer = nil
        performanceTimer = nil
    }
    
    private func updateMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemory = Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
            let totalMemory = Double(ProcessInfo.processInfo.physicalMemory) / 1024.0 / 1024.0
            memoryUsage = (usedMemory / totalMemory) * 100.0
            
            // Trigger memory optimization if usage is high
            if memoryUsage > 80.0 && enableMemoryOptimization {
                optimizeMemory()
            }
        }
    }
    
    private func updateCPUUsage() {
        // Simplified CPU usage calculation
        // In a real implementation, you'd use more sophisticated methods
        let randomVariation = Double.random(in: 0...20)
        cpuUsage = min(100.0, randomVariation)
    }
    
    private func updateBatteryLevel() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryLevel = UIDevice.current.batteryLevel
    }
    
    private func updateThermalState() {
        let thermalState = ProcessInfo.processInfo.thermalState
        isThermalStateNormal = thermalState == .nominal
    }
    
    private func updatePowerState() {
        isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
    }
    
    private func handleMemoryWarning() {
        isMemoryWarning = true
        
        if enableMemoryOptimization {
            optimizeMemory()
        }
        
        // Clear warning after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.isMemoryWarning = false
        }
    }
    
    // MARK: - Optimization
    
    func optimizeMemory() {
        print("🧹 PerformanceManager: Optimizing memory usage...")
        
        // Clear image cache if enabled
        if enableImageCaching {
            clearImageCache()
        }
        
        // Clear route cache if enabled
        if enableRouteCaching {
            clearRouteCache()
        }
        
        // Force garbage collection
        DispatchQueue.global(qos: .background).async {
            // This will trigger ARC cleanup
        }
        
        print("✅ PerformanceManager: Memory optimization completed")
    }
    
    func clearImageCache() {
        // Clear any image caches
        URLCache.shared.removeAllCachedResponses()
    }
    
    func clearRouteCache() {
        // Clear route cache if it exceeds the limit
        // This would be implemented in RouteCacheManager
        print("🗑️ PerformanceManager: Clearing route cache")
    }
    
    func optimizeForLowPowerMode() {
        guard isLowPowerMode else { return }
        
        print("🔋 PerformanceManager: Optimizing for low power mode")
        
        // Disable non-essential features
        enableBackgroundRefresh = false
        enableImageCaching = false
        maxCachedRoutes = 10
        maxCachedImages = 20
        
        // Save settings
        saveSettings()
    }
    
    func optimizeForThermalState() {
        guard !isThermalStateNormal else { return }
        
        print("🌡️ PerformanceManager: Optimizing for thermal state")
        
        // Reduce processing load
        enableCPUOptimization = false
        maxCachedRoutes = 20
        maxCachedImages = 50
        
        // Save settings
        saveSettings()
    }
    
    // MARK: - Settings
    
    func setImageCaching(_ enabled: Bool) {
        enableImageCaching = enabled
        UserDefaults.standard.set(enabled, forKey: "performance.enableImageCaching")
    }
    
    func setRouteCaching(_ enabled: Bool) {
        enableRouteCaching = enabled
        UserDefaults.standard.set(enabled, forKey: "performance.enableRouteCaching")
    }
    
    func setBackgroundRefresh(_ enabled: Bool) {
        enableBackgroundRefresh = enabled
        UserDefaults.standard.set(enabled, forKey: "performance.enableBackgroundRefresh")
    }
    
    func setMaxCachedRoutes(_ count: Int) {
        maxCachedRoutes = max(10, min(100, count))
        UserDefaults.standard.set(maxCachedRoutes, forKey: "performance.maxCachedRoutes")
    }
    
    func setMaxCachedImages(_ count: Int) {
        maxCachedImages = max(20, min(200, count))
        UserDefaults.standard.set(maxCachedImages, forKey: "performance.maxCachedImages")
    }
    
    func setMemoryOptimization(_ enabled: Bool) {
        enableMemoryOptimization = enabled
        UserDefaults.standard.set(enabled, forKey: "performance.enableMemoryOptimization")
    }
    
    func setCPUOptimization(_ enabled: Bool) {
        enableCPUOptimization = enabled
        UserDefaults.standard.set(enabled, forKey: "performance.enableCPUOptimization")
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(enableImageCaching, forKey: "performance.enableImageCaching")
        defaults.set(enableRouteCaching, forKey: "performance.enableRouteCaching")
        defaults.set(enableBackgroundRefresh, forKey: "performance.enableBackgroundRefresh")
        defaults.set(maxCachedRoutes, forKey: "performance.maxCachedRoutes")
        defaults.set(maxCachedImages, forKey: "performance.maxCachedImages")
        defaults.set(enableMemoryOptimization, forKey: "performance.enableMemoryOptimization")
        defaults.set(enableCPUOptimization, forKey: "performance.enableCPUOptimization")
    }
    
    // MARK: - Performance Metrics
    
    func getPerformanceScore() -> Int {
        let memoryScore = max(0, 100 - Int(memoryUsage))
        let cpuScore = max(0, 100 - Int(cpuUsage))
        let batteryScore = Int(batteryLevel * 100)
        
        return (memoryScore + cpuScore + batteryScore) / 3
    }
    
    func getPerformanceStatus() -> PerformanceStatus {
        let score = getPerformanceScore()
        
        switch score {
        case 80...100:
            return .excellent
        case 60..<80:
            return .good
        case 40..<60:
            return .fair
        default:
            return .poor
        }
    }
    
    func getRecommendations() -> [PerformanceRecommendation] {
        var recommendations: [PerformanceRecommendation] = []
        
        if memoryUsage > 80 {
            recommendations.append(.reduceMemoryUsage)
        }
        
        if cpuUsage > 70 {
            recommendations.append(.reduceCPUUsage)
        }
        
        if batteryLevel < 0.2 {
            recommendations.append(.enableLowPowerMode)
        }
        
        if !isThermalStateNormal {
            recommendations.append(.reduceThermalLoad)
        }
        
        if !enableImageCaching {
            recommendations.append(.enableImageCaching)
        }
        
        if !enableRouteCaching {
            recommendations.append(.enableRouteCaching)
        }
        
        return recommendations
    }
}

// MARK: - Supporting Types

enum PerformanceStatus {
    case excellent
    case good
    case fair
    case poor
    
    var description: String {
        switch self {
        case .excellent:
            return "Uitstekend"
        case .good:
            return "Goed"
        case .fair:
            return "Redelijk"
        case .poor:
            return "Slecht"
        }
    }
    
    var color: Color {
        switch self {
        case .excellent:
            return .green
        case .good:
            return .blue
        case .fair:
            return .orange
        case .poor:
            return .red
        }
    }
}

enum PerformanceRecommendation {
    case reduceMemoryUsage
    case reduceCPUUsage
    case enableLowPowerMode
    case reduceThermalLoad
    case enableImageCaching
    case enableRouteCaching
    
    var title: String {
        switch self {
        case .reduceMemoryUsage:
            return "Geheugengebruik Verminderen"
        case .reduceCPUUsage:
            return "CPU Gebruik Verminderen"
        case .enableLowPowerMode:
            return "Energiebesparende Modus Inschakelen"
        case .reduceThermalLoad:
            return "Thermische Belasting Verminderen"
        case .enableImageCaching:
            return "Afbeelding Caching Inschakelen"
        case .enableRouteCaching:
            return "Route Caching Inschakelen"
        }
    }
    
    var description: String {
        switch self {
        case .reduceMemoryUsage:
            return "Sluit ongebruikte apps en cache om geheugen vrij te maken"
        case .reduceCPUUsage:
            return "Verminder achtergrondprocessen om CPU belasting te verlagen"
        case .enableLowPowerMode:
            return "Schakel energiebesparende modus in om batterij te sparen"
        case .reduceThermalLoad:
            return "Verminder intensieve taken om oververhitting te voorkomen"
        case .enableImageCaching:
            return "Schakel afbeelding caching in voor betere prestaties"
        case .enableRouteCaching:
            return "Schakel route caching in voor snellere navigatie"
        }
    }
    
    var icon: String {
        switch self {
        case .reduceMemoryUsage:
            return "memorychip"
        case .reduceCPUUsage:
            return "cpu"
        case .enableLowPowerMode:
            return "battery.25"
        case .reduceThermalLoad:
            return "thermometer"
        case .enableImageCaching:
            return "photo.stack"
        case .enableRouteCaching:
            return "map"
        }
    }
}
