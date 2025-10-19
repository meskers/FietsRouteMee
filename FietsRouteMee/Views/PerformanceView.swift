//
//  PerformanceView.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 18/10/2025.
//

import SwiftUI

struct PerformanceView: View {
    @StateObject private var performanceManager = PerformanceManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Performance Status
                Section("Prestatie Status") {
                    PerformanceStatusCard(
                        status: performanceManager.getPerformanceStatus(),
                        score: performanceManager.getPerformanceScore(),
                        memoryUsage: performanceManager.memoryUsage,
                        cpuUsage: performanceManager.cpuUsage,
                        batteryLevel: performanceManager.batteryLevel
                    )
                }
                
                // System Status
                Section("Systeem Status") {
                    SystemStatusRow(
                        title: "Geheugengebruik",
                        value: "\(Int(performanceManager.memoryUsage))%",
                        status: performanceManager.memoryUsage > 80 ? .warning : .normal,
                        icon: "memorychip"
                    )
                    
                    SystemStatusRow(
                        title: "CPU Gebruik",
                        value: "\(Int(performanceManager.cpuUsage))%",
                        status: performanceManager.cpuUsage > 70 ? .warning : .normal,
                        icon: "cpu"
                    )
                    
                    SystemStatusRow(
                        title: "Batterij Niveau",
                        value: "\(Int(performanceManager.batteryLevel * 100))%",
                        status: performanceManager.batteryLevel < 0.2 ? .warning : .normal,
                        icon: "battery.100"
                    )
                    
                    SystemStatusRow(
                        title: "Thermische Status",
                        value: performanceManager.isThermalStateNormal ? "Normaal" : "Verhoogd",
                        status: performanceManager.isThermalStateNormal ? .normal : .warning,
                        icon: "thermometer"
                    )
                    
                    SystemStatusRow(
                        title: "Energiebesparende Modus",
                        value: performanceManager.isLowPowerMode ? "Aan" : "Uit",
                        status: performanceManager.isLowPowerMode ? .info : .normal,
                        icon: "battery.25"
                    )
                }
                
                // Performance Settings
                Section("Prestatie Instellingen") {
                    Toggle("Afbeelding Caching", isOn: $performanceManager.enableImageCaching)
                        .onChange(of: performanceManager.enableImageCaching) {
                            performanceManager.setImageCaching(performanceManager.enableImageCaching)
                        }
                        .accessibilityLabel("Afbeelding caching")
                        .accessibilityHint("Schakelt caching van afbeeldingen in voor betere prestaties")
                    
                    Toggle("Route Caching", isOn: $performanceManager.enableRouteCaching)
                        .onChange(of: performanceManager.enableRouteCaching) {
                            performanceManager.setRouteCaching(performanceManager.enableRouteCaching)
                        }
                        .accessibilityLabel("Route caching")
                        .accessibilityHint("Schakelt caching van routes in voor snellere navigatie")
                    
                    Toggle("Achtergrond Vernieuwing", isOn: $performanceManager.enableBackgroundRefresh)
                        .onChange(of: performanceManager.enableBackgroundRefresh) {
                            performanceManager.setBackgroundRefresh(performanceManager.enableBackgroundRefresh)
                        }
                        .accessibilityLabel("Achtergrond vernieuwing")
                        .accessibilityHint("Schakelt achtergrond vernieuwing in voor real-time updates")
                    
                    Toggle("Geheugen Optimalisatie", isOn: $performanceManager.enableMemoryOptimization)
                        .onChange(of: performanceManager.enableMemoryOptimization) {
                            performanceManager.setMemoryOptimization(performanceManager.enableMemoryOptimization)
                        }
                        .accessibilityLabel("Geheugen optimalisatie")
                        .accessibilityHint("Schakelt automatische geheugen optimalisatie in")
                    
                    Toggle("CPU Optimalisatie", isOn: $performanceManager.enableCPUOptimization)
                        .onChange(of: performanceManager.enableCPUOptimization) {
                            performanceManager.setCPUOptimization(performanceManager.enableCPUOptimization)
                        }
                        .accessibilityLabel("CPU optimalisatie")
                        .accessibilityHint("Schakelt CPU optimalisatie in voor betere prestaties")
                }
                
                // Cache Settings
                Section("Cache Instellingen") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Max. Gecachte Routes")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(performanceManager.maxCachedRoutes)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { Double(performanceManager.maxCachedRoutes) },
                                set: { performanceManager.setMaxCachedRoutes(Int($0)) }
                            ),
                            in: 10...100,
                            step: 10
                        )
                        .accessibilityLabel("Maximum gecachte routes")
                        .accessibilityValue("\(performanceManager.maxCachedRoutes) routes")
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Max. Gecachte Afbeeldingen")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(performanceManager.maxCachedImages)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { Double(performanceManager.maxCachedImages) },
                                set: { performanceManager.setMaxCachedImages(Int($0)) }
                            ),
                            in: 20...200,
                            step: 20
                        )
                        .accessibilityLabel("Maximum gecachte afbeeldingen")
                        .accessibilityValue("\(performanceManager.maxCachedImages) afbeeldingen")
                    }
                    .padding(.vertical, 4)
                }
                
                // Recommendations
                if !performanceManager.getRecommendations().isEmpty {
                    Section("Aanbevelingen") {
                        ForEach(performanceManager.getRecommendations(), id: \.self) { recommendation in
                            RecommendationRow(recommendation: recommendation)
                        }
                    }
                }
                
                // Actions
                Section("Acties") {
                    Button("Geheugen Optimaliseren") {
                        performanceManager.optimizeMemory()
                    }
                    .accessibilityLabel("Geheugen optimaliseren")
                    .accessibilityHint("Voert geheugen optimalisatie uit")
                    
                    Button("Cache Leegmaken") {
                        performanceManager.clearImageCache()
                        performanceManager.clearRouteCache()
                    }
                    .accessibilityLabel("Cache leegmaken")
                    .accessibilityHint("Wist alle caches")
                    
                    if performanceManager.isLowPowerMode {
                        Button("Optimaliseren voor Energiebesparing") {
                            performanceManager.optimizeForLowPowerMode()
                        }
                        .accessibilityLabel("Optimaliseren voor energiebesparing")
                        .accessibilityHint("Past instellingen aan voor energiebesparende modus")
                    }
                    
                    if !performanceManager.isThermalStateNormal {
                        Button("Optimaliseren voor Thermische Status") {
                            performanceManager.optimizeForThermalState()
                        }
                        .accessibilityLabel("Optimaliseren voor thermische status")
                        .accessibilityHint("Past instellingen aan voor thermische status")
                    }
                }
            }
            .navigationTitle("Prestaties")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Gereed") {
                        dismiss()
                    }
                    .accessibilityLabel("Sluit prestatie instellingen")
                }
            }
        }
    }
}

// MARK: - Performance Status Card

struct PerformanceStatusCard: View {
    let status: PerformanceStatus
    let score: Int
    let memoryUsage: Double
    let cpuUsage: Double
    let batteryLevel: Float
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prestatie Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(score)/100")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(status.color)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(status.description)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(status.color)
                }
            }
            
            HStack(spacing: 20) {
                PerformanceMetric(
                    title: "Geheugen",
                    value: "\(Int(memoryUsage))%",
                    color: memoryUsage > 80 ? .red : memoryUsage > 60 ? .orange : .green
                )
                
                PerformanceMetric(
                    title: "CPU",
                    value: "\(Int(cpuUsage))%",
                    color: cpuUsage > 70 ? .red : cpuUsage > 50 ? .orange : .green
                )
                
                PerformanceMetric(
                    title: "Batterij",
                    value: "\(Int(batteryLevel * 100))%",
                    color: batteryLevel < 0.2 ? .red : batteryLevel < 0.5 ? .orange : .green
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Prestatie score: \(score) van 100, status: \(status.description)")
    }
}

// MARK: - Performance Metric

struct PerformanceMetric: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - System Status Row

struct SystemStatusRow: View {
    let title: String
    let value: String
    let status: SystemStatus
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(status.color)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(status.color)
                .fontWeight(.medium)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Recommendation Row

struct RecommendationRow: View {
    let recommendation: PerformanceRecommendation
    
    var body: some View {
        HStack {
            Image(systemName: recommendation.icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recommendation.title): \(recommendation.description)")
    }
}

// MARK: - Supporting Types

enum SystemStatus {
    case normal
    case warning
    case info
    
    var color: Color {
        switch self {
        case .normal:
            return .green
        case .warning:
            return .orange
        case .info:
            return .blue
        }
    }
}

#Preview {
    PerformanceView()
}
