//
//  ProfileView.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 08/10/2025.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @ObservedObject var favoritesManager: FavoritesManager
    @ObservedObject var weatherManager: WeatherManager
    @ObservedObject var routeManager: RouteManager
    @ObservedObject private var coreDataManager = CoreDataManager.shared
    @StateObject private var routeCacheManager = RouteCacheManager()
    @StateObject private var userProfileManager = UserProfileManager()
    @State private var showingSettings = false
    @State private var showingStatistics = false
    @State private var showingResetConfirm = false
    @State private var isResetting = false
    @State private var showingPhotoPicker = false
    @State private var showingNameEditor = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    ProfileHeader(
                        userProfileManager: userProfileManager,
                        showingPhotoPicker: $showingPhotoPicker,
                        showingNameEditor: $showingNameEditor
                    )
                    
                    // Statistics Cards (dynamic)
                    StatisticsSection(
                        showingStatistics: $showingStatistics,
                        coreDataManager: coreDataManager,
                        favoritesManager: favoritesManager
                    )
                    
                    // Quick Actions
                    QuickActionsSection()
                    
                    // Settings
                    SettingsSection(showingSettings: $showingSettings)
                    
                    // Weather Preferences
                    WeatherPreferencesSection(weatherManager: weatherManager)
                    
                    // App Info
                    AppInfoSection()
                    
                    // Danger Zone
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Opschonen")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Button(action: { showingResetConfirm = true }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Verwijder alle routes en opgeslagen data")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("Profiel")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingStatistics) {
            StatisticsView()
        }
        .confirmationDialog(
            "Weet je zeker dat je alle app data wilt verwijderen?",
            isPresented: $showingResetConfirm,
            titleVisibility: .visible
        ) {
            Button("Verwijder alles", role: .destructive) {
                resetAllData()
            }
            Button("Annuleer", role: .cancel) {}
        } message: {
            Text("Dit verwijdert routes, favorieten, cache, offline kaarten en instellingen.")
        }
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedPhotoItem) {
            Task {
                if let newItem = selectedPhotoItem,
                   let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        userProfileManager.updateUserPhoto(image)
                    }
                }
            }
        }
        .sheet(isPresented: $showingNameEditor) {
            NameEditorView(userProfileManager: userProfileManager)
        }
    }
}

struct ProfileHeader: View {
    @ObservedObject var userProfileManager: UserProfileManager
    @Binding var showingPhotoPicker: Bool
    @Binding var showingNameEditor: Bool
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile Picture with modern design
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.3), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                if let userPhoto = userProfileManager.userPhoto {
                    Image(uiImage: userPhoto)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(.white, lineWidth: 3)
                        )
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                }
                
                // Camera button overlay
                Button(action: {
                    showingPhotoPicker = true
                }) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(.green, in: Circle())
                        .overlay(
                            Circle()
                                .stroke(.white, lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .offset(x: 40, y: 40)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
            }
            
            // User Name with edit functionality
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(userProfileManager.userName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Button(action: {
                        showingNameEditor = true
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundColor(.green)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Text(userProfileManager.formattedJoinDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.green.opacity(0.3), .blue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            isAnimating = true
        }
    }
}

struct StatisticsSection: View {
    @Binding var showingStatistics: Bool
    @ObservedObject var coreDataManager: CoreDataManager
    @ObservedObject var favoritesManager: FavoritesManager
    
    var totalRoutes: Int {
        coreDataManager.savedRoutes.count
    }
    
    var totalDistanceKm: String {
        let distance = coreDataManager.savedRoutes
            .compactMap { $0.distance }
            .reduce(0, +)
        return String(format: "%.1f km", distance / 1000)
    }
    
    var totalDuration: String {
        let seconds = coreDataManager.savedRoutes
            .compactMap { $0.duration }
            .reduce(0, +)
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return "\(hours)u \(minutes)m"
    }
    
    var favoritesCount: Int {
        favoritesManager.getFavoriteCount()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Statistieken")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Alles bekijken") {
                    showingStatistics = true
                }
                .font(.subheadline)
                .foregroundColor(.green)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCard(
                    title: "Totaal Routes",
                    value: "\(totalRoutes)",
                    icon: "map",
                    color: .blue
                )
                StatCard(
                    title: "Afstand",
                    value: totalDistanceKm,
                    icon: "ruler",
                    color: .green
                )
                StatCard(
                    title: "Tijd",
                    value: totalDuration,
                    icon: "clock",
                    color: .orange
                )
                StatCard(
                    title: "Favorieten",
                    value: "\(favoritesCount)",
                    icon: "heart.fill",
                    color: .red
                )
            }
        }
    }
}

struct QuickActionsSection: View {
    @State private var showingNewRoute = false
    @State private var showingLiveTracking = false
    @State private var showingShareSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Snelle Acties")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionCard(
                    title: "Nieuwe Route",
                    icon: "plus.circle.fill",
                    color: .green
                ) {
                    showingNewRoute = true
                }
                
                QuickActionCard(
                    title: "Live Tracking",
                    icon: "location.fill",
                    color: .red
                ) {
                    showingLiveTracking = true
                }
                
                QuickActionCard(
                    title: "Delen",
                    icon: "square.and.arrow.up",
                    color: .purple
                ) {
                    showingShareSheet = true
                }
            }
        }
        .sheet(isPresented: $showingNewRoute) {
            SearchView(routeManager: RouteManager.shared, locationManager: LocationManager.shared)
        }
        .sheet(isPresented: $showingLiveTracking) {
            ActivityTrackingView()
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareAppView()
        }
    }
}

struct SettingsSection: View {
    @Binding var showingSettings: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Instellingen")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                SettingsRow(
                    title: "Notificaties",
                    icon: "bell.fill",
                    color: .orange
                ) {
                    showingSettings = true
                }
                
                SettingsRow(
                    title: "Privacy",
                    icon: "lock.fill",
                    color: .blue
                ) {
                    showingSettings = true
                }
                
                SettingsRow(
                    title: "Account",
                    icon: "person.circle.fill",
                    color: .green
                ) {
                    showingSettings = true
                }
                
                SettingsRow(
                    title: "Over de App",
                    icon: "info.circle.fill",
                    color: .gray
                ) {
                    showingSettings = true
                }
            }
        }
    }
}

struct WeatherPreferencesSection: View {
    @ObservedObject var weatherManager: WeatherManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weer Voorkeuren")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                WeatherPreferenceRow(
                    title: "Weer Updates",
                    subtitle: "Krijg waarschuwingen voor slecht weer",
                    isEnabled: weatherManager.weatherAlertsEnabled
                ) {
                    weatherManager.toggleWeatherAlerts()
                }
                
                WeatherPreferenceRow(
                    title: "Temperatuur",
                    subtitle: "Toon temperatuur op kaart",
                    isEnabled: weatherManager.temperatureDisplayEnabled
                ) {
                    weatherManager.toggleTemperatureDisplay()
                }
            }
        }
    }
}

struct AppInfoSection: View {
    // Version info from Info.plist
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.3"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "202510191349"
    }
    
    private var lastUpdate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "nl_NL")
        return formatter.string(from: Date())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("App Informatie")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                InfoRow(title: "Versie", value: appVersion)
                InfoRow(title: "Build", value: buildNumber)
                InfoRow(title: "Laatste Update", value: lastUpdate)
            }
        }
    }
}

private extension ProfileView {
    func resetAllData() {
        isResetting = true
        
        // Clear in-memory routes
        routeManager.clearRoutes()
        
        // Reset Core Data store
        CoreDataManager.shared.resetPersistentStore()
        
        // Clear favorites in memory (will re-sync from Core Data which is now empty)
        favoritesManager.favoriteRoutes.removeAll()
        
        // Clear caches
        routeCacheManager.clearAllCaches()
        
        // Reset user profile
        userProfileManager.resetProfile()
        
        // Clear UserDefaults flags used by the app
        let keysToRemove: [String] = [
            "weather_alerts_enabled",
            "temperature_display_enabled",
            "cached_routes"
        ]
        for key in keysToRemove { UserDefaults.standard.removeObject(forKey: key) }
        
        // Haptics or simple confirmation could be added here
        isResetting = false
    }
}


struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WeatherPreferenceRow: View {
    let title: String
    let subtitle: String
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: .constant(isEnabled))
                .onChange(of: isEnabled) {
                    action()
                }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct SettingsView: View {
    @ObservedObject private var settingsManager = AppSettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingVoiceSettings = false
    @State private var showingMapSettings = false
    @State private var showingPrivacySettings = false
    @State private var showingAppInfo = false
    
    var body: some View {
        NavigationStack {
            List {
                // Voice Navigation Section
                Section {
                    NavigationLink(destination: VoiceSettingsDetailView(settingsManager: settingsManager)) {
                        HStack {
                            Image(systemName: "speaker.wave.3.fill")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Spraaknavigatie")
                                    .font(.headline)
                                Text("Volume: \(Int(settingsManager.voiceVolume * 100))% • Snelheid: \(Int(settingsManager.voiceSpeed * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("Navigatie")
                }
                
                // Map Settings Section
                Section {
                    NavigationLink(destination: MapSettingsDetailView(settingsManager: settingsManager)) {
                        HStack {
                            Image(systemName: "map.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Kaartweergave")
                                    .font(.headline)
                                Text("Type: \(settingsManager.mapType.displayName) • Verkeer: \(settingsManager.showsTraffic ? "Aan" : "Uit")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("Kaart")
                }
                
                // Privacy Section
                Section {
                    NavigationLink(destination: PrivacySettingsDetailView(settingsManager: settingsManager)) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Privacy & Toegang")
                                    .font(.headline)
                                Text("Locatie: \(settingsManager.locationPermissionStatus.description)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("Privacy")
                }
                
                // App Info Section
                Section {
                    NavigationLink(destination: AppInfoDetailView()) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Over de App")
                                    .font(.headline)
                                Text("Versie 1.0.3 • GitHub Repository")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("Informatie")
                }
                
                // Reset Section
                Section {
                    Button("Reset naar Standaard") {
                        settingsManager.resetToDefaults()
                    }
                    .foregroundColor(.red)
                } header: {
                    Text("Reset")
                } footer: {
                    Text("Herstel alle instellingen naar de standaardwaarden.")
                }
            }
            .navigationTitle("Instellingen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Klaar") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            settingsManager.checkPermissions()
        }
    }
}

struct VoiceSettingsDetailView: View {
    @ObservedObject var settingsManager: AppSettingsManager
    
    var body: some View {
        List {
            Section {
                Toggle("Spraaknavigatie", isOn: $settingsManager.isVoiceEnabled)
                    .font(.headline)
            } header: {
                Text("Algemeen")
            } footer: {
                Text("Schakel spraaknavigatie in of uit voor turn-by-turn instructies.")
            }
            
            if settingsManager.isVoiceEnabled {
                Section {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Volume")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(settingsManager.voiceVolume * 100))%")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $settingsManager.voiceVolume, in: 0...1, step: 0.1)
                            .accentColor(.green)
                    }
                    
                    VStack(spacing: 16) {
                        HStack {
                            Text("Snelheid")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(settingsManager.voiceSpeed * 100))%")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $settingsManager.voiceSpeed, in: 0.1...1, step: 0.1)
                            .accentColor(.green)
                    }
                    
                    HStack {
                        Text("Taal")
                            .font(.subheadline)
                        Spacer()
                        Picker("Taal", selection: $settingsManager.voiceLanguage) {
                            Text("Nederlands").tag("nl-NL")
                            Text("English").tag("en-US")
                            Text("English (UK)").tag("en-GB")
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                } header: {
                    Text("Spraakinstellingen")
                } footer: {
                    Text("Pas volume, snelheid en taal aan voor optimale spraaknavigatie.")
                }
                
                Section {
                    Toggle("Voorafgaande waarschuwing", isOn: .constant(true))
                    Toggle("Herhaling bij gemiste afslag", isOn: .constant(true))
                    Toggle("Aankomstmelding", isOn: .constant(true))
                    Toggle("Verkeerswaarschuwingen", isOn: .constant(false))
                } header: {
                    Text("Geavanceerde Opties")
                } footer: {
                    Text("Extra spraaknavigatie functies voor betere gebruikerservaring.")
                }
                
                Section {
                    HStack {
                        Text("Test Spraak")
                            .font(.subheadline)
                        Spacer()
                        Button("Speel Voorbeeld") {
                            // Test voice functionality
                        }
                        .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Spraakkwaliteit")
                            .font(.subheadline)
                        Spacer()
                        Picker("Kwaliteit", selection: .constant("Hoog")) {
                            Text("Hoog").tag("Hoog")
                            Text("Gemiddeld").tag("Gemiddeld")
                            Text("Laag").tag("Laag")
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                } header: {
                    Text("Test & Kwaliteit")
                } footer: {
                    Text("Test je spraakinstellingen en pas de kwaliteit aan.")
                }
            }
        }
        .navigationTitle("Spraaknavigatie")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MapSettingsDetailView: View {
    @ObservedObject var settingsManager: AppSettingsManager
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Kaarttype")
                        .font(.headline)
                    Spacer()
                    Picker("Kaarttype", selection: $settingsManager.mapType) {
                        ForEach(AppSettingsManager.MapType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            } header: {
                Text("Weergave")
            } footer: {
                Text("Kies tussen standaard, satelliet of hybride kaartweergave.")
            }
            
            Section {
                Toggle("Verkeer tonen", isOn: $settingsManager.showsTraffic)
                Toggle("Gebouwen tonen", isOn: $settingsManager.showsBuildings)
                Toggle("Kompas tonen", isOn: $settingsManager.showsCompass)
                Toggle("Schaal tonen", isOn: $settingsManager.showsScale)
            } header: {
                Text("Kaartelementen")
            } footer: {
                Text("Schakel verschillende kaartelementen in of uit voor een betere navigatie-ervaring.")
            }
            
            Section {
                Toggle("Automatisch zoomen", isOn: .constant(true))
                Toggle("Rotatie met richting", isOn: .constant(true))
                Toggle("3D weergave", isOn: .constant(false))
                Toggle("Nachtthema", isOn: .constant(false))
                Toggle("Contourlijnen", isOn: .constant(true))
            } header: {
                Text("Navigatie Opties")
            } footer: {
                Text("Geavanceerde kaartinstellingen voor tijdens het navigeren.")
            }
            
            Section {
                HStack {
                    Text("Zoom niveau")
                        .font(.subheadline)
                    Spacer()
                    Text("Gemiddeld")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Kaartstijl")
                        .font(.subheadline)
                    Spacer()
                    Picker("Stijl", selection: .constant("Standaard")) {
                        Text("Standaard").tag("Standaard")
                        Text("Minimaal").tag("Minimaal")
                        Text("Satelliet").tag("Satelliet")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                HStack {
                    Text("Cache grootte")
                        .font(.subheadline)
                    Spacer()
                    Text("125 MB")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Geavanceerd")
            } footer: {
                Text("Pas geavanceerde kaartinstellingen aan voor optimale prestaties.")
            }
            
            Section {
                Button("Cache Wissen") {
                    // Clear map cache
                }
                .foregroundColor(.orange)
                
                Button("Kaart Resetten") {
                    // Reset map settings
                }
                .foregroundColor(.red)
            } header: {
                Text("Onderhoud")
            } footer: {
                Text("Beheer kaartgegevens en cache voor optimale prestaties.")
            }
        }
        .navigationTitle("Kaartweergave")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacySettingsDetailView: View {
    @ObservedObject var settingsManager: AppSettingsManager
    
    var body: some View {
        List {
            Section {
                PermissionRow(
                    title: "Locatie",
                    description: "Voor routeberekening en navigatie",
                    status: settingsManager.locationPermissionStatus.description,
                    isGranted: settingsManager.locationPermissionStatus == .authorizedWhenInUse || settingsManager.locationPermissionStatus == .authorizedAlways
                )
            } header: {
                Text("App Toegang")
            } footer: {
                Text("Beheer welke gegevens de app kan gebruiken voor navigatie.")
            }
            
            Section {
                Button("Open App Instellingen") {
                    settingsManager.openAppSettings()
                }
                .foregroundColor(.blue)
                
                Button("Toestemmingen Controleren") {
                    settingsManager.checkPermissions()
                }
                .foregroundColor(.green)
            } header: {
                Text("Beheer")
            } footer: {
                Text("Ga naar iOS Instellingen om app-toegang te wijzigen.")
            }
            
            Section {
                Toggle("Anonieme statistieken", isOn: .constant(true))
                Toggle("Crash rapporten", isOn: .constant(true))
                Toggle("Gebruiksgegevens", isOn: .constant(false))
                Toggle("Route geschiedenis", isOn: .constant(true))
            } header: {
                Text("Privacy Opties")
            } footer: {
                Text("Beheer welke gegevens worden gedeeld voor app-verbetering.")
            }
            
            Section {
                HStack {
                    Text("Gegevens opslag")
                        .font(.subheadline)
                    Spacer()
                    Text("Lokaal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Route geschiedenis")
                        .font(.subheadline)
                    Spacer()
                    Text("30 dagen")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Cache opslag")
                        .font(.subheadline)
                    Spacer()
                    Text("125 MB")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Gegevensbeheer")
            } footer: {
                Text("Beheer hoe je gegevens worden opgeslagen en bewaard.")
            }
            
            Section {
                Button("Alle Gegevens Wissen") {
                    // Clear all data
                }
                .foregroundColor(.red)
                
                Button("Route Geschiedenis Wissen") {
                    // Clear route history
                }
                .foregroundColor(.orange)
                
                Button("Cache Wissen") {
                    // Clear cache
                }
                .foregroundColor(.blue)
            } header: {
                Text("Gegevens Wissen")
            } footer: {
                Text("Verwijder opgeslagen gegevens om je privacy te beschermen.")
            }
        }
        .navigationTitle("Privacy & Toegang")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            settingsManager.checkPermissions()
        }
    }
}

struct AppInfoDetailView: View {
    // Version info from Info.plist
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.3"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "202510191349"
    }
    
    private var lastUpdate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "nl_NL")
        return formatter.string(from: Date())
    }
    
    var body: some View {
        List {
            Section {
                InfoRow(title: "App Naam", value: "FietsRouteMee")
                InfoRow(title: "Versie", value: appVersion)
                InfoRow(title: "Build", value: buildNumber)
                InfoRow(title: "Ontwikkelaar", value: "Cor Meskers")
                InfoRow(title: "Laatste Update", value: lastUpdate)
                InfoRow(title: "iOS Vereist", value: "18.0+")
            } header: {
                Text("App Informatie")
            }
            
            Section {
                Button(action: {
                    if let url = URL(string: "https://github.com/cormeskers/FietsRouteMee") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.blue)
                        Text("GitHub Repository")
                            .foregroundColor(.blue)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                
                Button(action: {
                    if let url = URL(string: "https://github.com/cormeskers/FietsRouteMee/issues") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Rapporteer Bug")
                            .foregroundColor(.orange)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
                
                Button(action: {
                    if let url = URL(string: "https://github.com/cormeskers/FietsRouteMee/releases") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.down.circle")
                            .foregroundColor(.green)
                        Text("Release Notes")
                            .foregroundColor(.green)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                Button(action: {
                    if let url = URL(string: "https://github.com/cormeskers/FietsRouteMee/wiki") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "book")
                            .foregroundColor(.purple)
                        Text("Documentatie")
                            .foregroundColor(.purple)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.purple)
                            .font(.caption)
                    }
                }
            } header: {
                Text("Ontwikkeling")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("FietsRouteMee")
                        .font(.headline)
                    Text("Een moderne fietsnavigatie app voor iOS, ontwikkeld met SwiftUI en MapKit. Perfect voor dagelijkse fietsritten en routeplanning.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Over")
            }
            
            Section {
                HStack {
                    Text("Licentie")
                        .font(.subheadline)
                    Spacer()
                    Text("MIT")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Open Source")
                        .font(.subheadline)
                    Spacer()
                    Text("Ja")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Privacy")
                        .font(.subheadline)
                    Spacer()
                    Text("Lokaal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Licentie & Privacy")
            } footer: {
                Text("Deze app respecteert je privacy en slaat gegevens lokaal op.")
            }
            
            Section {
                Button("App Resetten") {
                    // Reset app data
                }
                .foregroundColor(.red)
                
                Button("Cache Wissen") {
                    // Clear cache
                }
                .foregroundColor(.orange)
                
                Button("Diagnostiek Verzenden") {
                    // Send diagnostics
                }
                .foregroundColor(.blue)
            } header: {
                Text("Onderhoud")
            } footer: {
                Text("Beheer app-gegevens en cache voor optimale prestaties.")
            }
        }
        .navigationTitle("Over de App")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PermissionRow: View {
    let title: String
    let description: String
    let status: String
    let isGranted: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(status)
                    .font(.subheadline)
                    .foregroundColor(isGranted ? .green : .red)
                
                Image(systemName: isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isGranted ? .green : .red)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}



struct StatisticsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Cycling Statistics") {
                    Text("Total Distance: 0 km")
                    Text("Total Time: 0 hours")
                    Text("Routes Completed: 0")
                }
                Section("Achievements") {
                    Text("First Route")
                    Text("Distance Milestone")
                }
            }
            .navigationTitle("Statistieken")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ProfileView(
        favoritesManager: FavoritesManager(),
        weatherManager: WeatherManager(),
        routeManager: RouteManager.shared
    )
}

struct NameEditorView: View {
    @ObservedObject var userProfileManager: UserProfileManager
    @Environment(\.dismiss) private var dismiss
    @State private var newName: String = ""
    @State private var isEditing = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Wijzig je naam")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding(.top, 20)
                
                // Text Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Naam")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextField("Voer je naam in", text: $newName)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)
                        .onSubmit {
                            saveName()
                        }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: saveName) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Opslaan")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Button("Annuleren") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            newName = userProfileManager.userName
        }
    }
    
    private func saveName() {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        userProfileManager.updateUserName(trimmedName)
        dismiss()
    }
}

