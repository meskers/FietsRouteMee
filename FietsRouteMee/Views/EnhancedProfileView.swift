//
//  EnhancedProfileView.swift
//  FietsRouteMee
//
//  Enhanced Profile View with MapLibre and cycling-specific settings
//

import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct EnhancedProfileView: View {
    @StateObject private var favoritesManager = FavoritesManager()
    @StateObject private var weatherManager = WeatherManager()
    @StateObject private var routeManager = RouteManager.shared
    @StateObject private var offlineMapsManager = OfflineMapsManager()
    @ObservedObject private var appSettingsManager = AppSettingsManager.shared
    @ObservedObject private var mapLibreService = MapLibreService.shared
    @ObservedObject private var fietsknooppuntenService = FietsknooppuntenService.shared
    
    @State private var showingImagePicker = false
    @State private var showingNewRoute = false
    @State private var showingOfflineMaps = false
    @State private var selectedImage: UIImage?
    @State private var showingSettings = false
    @State private var showingAbout = false
    @State private var showingDataExport = false
    @State private var showingFietsknooppunten = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    ProfileHeaderView()
                    
                    // Quick Stats
                    QuickStatsView()
                    
                    // Enhanced Settings Sections
                    VStack(spacing: 16) {
                        // Map & Navigation Settings
                        SettingsSectionView(
                            title: "Kaart & Navigatie",
                            icon: "map.fill",
                            color: .blue
                        ) {
                            VStack(spacing: 12) {
                                SettingsToggleRow(
                                    title: "MapLibre Kaarten",
                                    subtitle: "Betere fietsdata en offline ondersteuning",
                                    isOn: $appSettingsManager.mapLibreEnabled
                                )
                                
                                SettingsToggleRow(
                                    title: "Fietsknooppunten",
                                    subtitle: "Nederlandse fietsknooppunten weergeven",
                                    isOn: $appSettingsManager.showKnooppunten
                                )
                                
                                SettingsToggleRow(
                                    title: "Fiets POI's",
                                    subtitle: "Fietsenwinkels, reparatiepunten, etc.",
                                    isOn: $appSettingsManager.showCyclingPOIs
                                )
                                
                                SettingsToggleRow(
                                    title: "Offline Routing",
                                    subtitle: "Route berekening zonder internet",
                                    isOn: $appSettingsManager.useOfflineRouting
                                )
                                
                                SettingsToggleRow(
                                    title: "Verkeer",
                                    subtitle: "Verkeersinformatie weergeven",
                                    isOn: $appSettingsManager.showsTraffic
                                )
                            }
                        }
                        
                        // Voice & Audio Settings
                        SettingsSectionView(
                            title: "Stem & Audio",
                            icon: "speaker.wave.3.fill",
                            color: .green
                        ) {
                            VStack(spacing: 12) {
                                SettingsToggleRow(
                                    title: "Stem Navigatie",
                                    subtitle: "Gesproken route instructies",
                                    isOn: $appSettingsManager.isVoiceEnabled
                                )
                                
                                SettingsSliderRow(
                                    title: "Volume",
                                    subtitle: "Geluidssterkte van stem",
                                    value: $appSettingsManager.voiceVolume,
                                    range: 0...1
                                )
                                
                                SettingsSliderRow(
                                    title: "Snelheid",
                                    subtitle: "Spraaksnelheid",
                                    value: $appSettingsManager.voiceSpeed,
                                    range: 0...1
                                )
                            }
                        }
                        
                        // Route Preferences
                        SettingsSectionView(
                            title: "Route Voorkeuren",
                            icon: "bicycle",
                            color: .orange
                        ) {
                            VStack(spacing: 12) {
                                SettingsPickerRow(
                                    title: "Fietstype",
                                    subtitle: "Type fiets voor route berekening",
                                    selection: $appSettingsManager.selectedBikeType,
                                    options: BikeType.allCases
                                )
                                
                                SettingsToggleRow(
                                    title: "Vermijd Snelwegen",
                                    subtitle: "Geen snelwegen in routes",
                                    isOn: $appSettingsManager.avoidHighways
                                )
                                
                                SettingsToggleRow(
                                    title: "Voorkeur Fietspaden",
                                    subtitle: "Prioriteit voor fietspaden",
                                    isOn: $appSettingsManager.preferBikePaths
                                )
                                
                                SettingsToggleRow(
                                    title: "Voorkeur Natuur",
                                    subtitle: "Routes door natuurgebieden",
                                    isOn: $appSettingsManager.preferNature
                                )
                            }
                        }
                        
                        // Data & Privacy
                        SettingsSectionView(
                            title: "Data & Privacy",
                            icon: "shield.fill",
                            color: .purple
                        ) {
                            VStack(spacing: 12) {
                                Button(action: { showingDataExport = true }) {
                                    SettingsActionRow(
                                        title: "Data Exporteren",
                                        subtitle: "Exporteer je routes en instellingen",
                                        icon: "square.and.arrow.up"
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: { 
                                    CoreDataManager.shared.clearAllData()
                                }) {
                                    SettingsActionRow(
                                        title: "Data Wissen",
                                        subtitle: "Verwijder alle opgeslagen routes",
                                        icon: "trash",
                                        color: .red
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // Accessibility & Performance
                        SettingsSectionView(
                            title: "Toegankelijkheid & Prestaties",
                            icon: "gear",
                            color: .indigo
                        ) {
                            VStack(spacing: 12) {
                                NavigationLink(destination: AccessibilityView()) {
                                    SettingsActionRow(
                                        title: "Toegankelijkheid",
                                        subtitle: "VoiceOver, Switch Control en meer",
                                        icon: "accessibility"
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                NavigationLink(destination: PerformanceView()) {
                                    SettingsActionRow(
                                        title: "Prestaties",
                                        subtitle: "Geheugen, CPU en optimalisatie",
                                        icon: "speedometer"
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // Special Features
                        SettingsSectionView(
                            title: "Speciale Functies",
                            icon: "star.fill",
                            color: .yellow
                        ) {
                            VStack(spacing: 12) {
                                Button(action: { showingFietsknooppunten = true }) {
                                    SettingsActionRow(
                                        title: "Fietsknooppunten Planner",
                                        subtitle: "Plan routes via Nederlandse knooppunten",
                                        icon: "bicycle"
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: { showingOfflineMaps = true }) {
                                    SettingsActionRow(
                                        title: "Offline Kaarten",
                                        subtitle: "Download kaarten voor offline gebruik",
                                        icon: "map"
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // About Section
                        SettingsSectionView(
                            title: "Over de App",
                            icon: "info.circle.fill",
                            color: .gray
                        ) {
                            VStack(spacing: 12) {
                                Button(action: { showingAbout = true }) {
                                    SettingsActionRow(
                                        title: "App Informatie",
                                        subtitle: "Versie, ontwikkelaar en meer",
                                        icon: "info.circle"
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: { 
                                    if let url = URL(string: "https://github.com/cormeskers/FietsRouteMee") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    SettingsActionRow(
                                        title: "GitHub Repository",
                                        subtitle: "Bekijk de broncode",
                                        icon: "link"
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Profiel")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
                    // Handle image selection
                }
            }
            .sheet(isPresented: $showingNewRoute) {
                SearchView(
                    routeManager: routeManager,
                    locationManager: LocationManager.shared
                )
            }
            .sheet(isPresented: $showingDataExport) {
                DataExportView()
            }
            .sheet(isPresented: $showingFietsknooppunten) {
                EnhancedFietsknooppuntenPlannerView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }

// MARK: - Profile Header

struct ProfileHeaderView: View {
    @AppStorage("userName") private var userName = "Fietser"
    @AppStorage("userPhoto") private var userPhotoData: Data?
    @State private var showingImagePicker = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Photo
            Button(action: { showingImagePicker = true }) {
                Group {
                    if let photoData = userPhotoData,
                       let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: 4)
                        .shadow(radius: 4)
                )
            }
            .buttonStyle(.plain)
            
            // User Name
            TextField("Je naam", text: $userName)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
            
            Text("Ontwikkeld door Cor Meskers")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: Binding(
                get: { nil },
                set: { image in
                    if let image = image, let imageData = image.jpegData(compressionQuality: 0.8) {
                        userPhotoData = imageData
                    }
                }
            ))
        }
    }
}

// MARK: - Quick Stats

struct QuickStatsView: View {
    @StateObject private var routeManager = RouteManager.shared
    @StateObject private var favoritesManager = FavoritesManager()
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Routes",
                value: "\(routeManager.routes.count)",
                icon: "map",
                color: .blue
            )
            
            StatCard(
                title: "Favorieten",
                value: "0", // favoritesManager.favorites.count
                icon: "heart.fill",
                color: .red
            )
            
            StatCard(
                title: "Totaal KM",
                value: "\(Int(routeManager.routes.reduce(0) { $0 + $1.distance / 1000 }))",
                icon: "ruler",
                color: .green
            )
        }
    }
}

// MARK: - Settings Components

struct SettingsSectionView<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            content
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

struct SettingsSliderRow: View {
    let title: String
    let subtitle: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(Int(value * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $value, in: range)
                .accentColor(.blue)
        }
    }
}

struct SettingsPickerRow<T: CaseIterable & RawRepresentable & Hashable>: View where T.RawValue == String {
    let title: String
    let subtitle: String
    @Binding var selection: T
    let options: [T]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Picker("", selection: $selection) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    Text(option.rawValue.capitalized).tag(option)
                }
            }
            .pickerStyle(.menu)
        }
    }
}

struct SettingsActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    var color: Color = .blue
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Version info from Info.plist
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon
                    Image("SplashIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    
                    // App Info
                    VStack(spacing: 8) {
                        Text("FietsRouteMee")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Versie \(appVersion)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Ontwikkeld door Cor Meskers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Nieuwe Functies")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        FeatureRow(icon: "map.fill", title: "MapLibre Integratie", description: "Betere fietsdata en offline kaarten")
                        FeatureRow(icon: "bicycle", title: "Nederlandse Fietsknooppunten", description: "Plan routes via het Nederlandse knooppuntennetwerk")
                        FeatureRow(icon: "wifi.slash", title: "Offline Routing", description: "Route berekening zonder internetverbinding")
                        FeatureRow(icon: "location.fill", title: "Fiets POI's", description: "Fietsenwinkels, reparatiepunten en meer")
                        FeatureRow(icon: "speaker.wave.3.fill", title: "Verbeterde Stem", description: "Betere Nederlandse spraaknavigatie")
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Links
                    VStack(spacing: 12) {
                        LinkButton(
                            title: "GitHub Repository",
                            subtitle: "Bekijk de broncode",
                            url: "https://github.com/cormeskers/FietsRouteMee"
                        )
                        
                        LinkButton(
                            title: "Privacy Policy",
                            subtitle: "Hoe we je data beschermen",
                            url: "https://github.com/cormeskers/FietsRouteMee/blob/main/PRIVACY.md"
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Over de App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sluiten") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct LinkButton: View {
    let title: String
    let subtitle: String
    let url: String
    
    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    EnhancedProfileView()
}
