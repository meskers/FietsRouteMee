//
//  ActivityTrackingView.swift
//  FietsRouteMee
//
//  Strava-style Activity Tracking View
//

import SwiftUI
import MapKit

struct ActivityTrackingView: View {
    @StateObject private var activityTracker = ActivityTracker.shared
    @State private var showingActivityList = false
    @State private var showingStartActivity = false
    @State private var selectedActivity: CyclingActivity?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if activityTracker.isTracking {
                    activeTrackingView
                } else {
                    inactiveView
                }
            }
            .navigationTitle("Activiteiten")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingActivityList = true
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                }
            }
            .sheet(isPresented: $showingActivityList) {
                ActivityListView()
            }
            .sheet(isPresented: $showingStartActivity) {
                StartActivityView()
            }
            .sheet(item: $selectedActivity) { activity in
                ActivityDetailView(activity: activity)
            }
        }
    }
    
    // MARK: - Active Tracking View
    
    private var activeTrackingView: some View {
        VStack(spacing: 0) {
            // Map showing current route
            if let activity = activityTracker.currentActivity {
                ActivityMapView(trackPoints: activity.trackPoints)
                    .frame(height: 300)
            }
            
            // Stats
            ScrollView {
                VStack(spacing: 20) {
                    // Time
                    ActivityStatCard(
                        icon: "clock.fill",
                        title: "Tijd",
                        value: activityTracker.currentActivity?.formattedDuration ?? "0:00",
                        color: .blue
                    )
                    
                    // Distance
                    ActivityStatCard(
                        icon: "arrow.left.and.right",
                        title: "Afstand",
                        value: activityTracker.currentActivity?.formattedDistance ?? "0 km",
                        color: .green
                    )
                    
                    // Speed
                    HStack(spacing: 16) {
                        ActivityStatCard(
                            icon: "speedometer",
                            title: "Gem. Snelheid",
                            value: activityTracker.currentActivity?.formattedAvgSpeed ?? "0 km/h",
                            color: .orange
                        )
                        
                        ActivityStatCard(
                            icon: "bolt.fill",
                            title: "Max Snelheid",
                            value: String(format: "%.1f km/h", activityTracker.currentActivity?.maxSpeed ?? 0),
                            color: .red
                        )
                    }
                    
                    // Elevation
                    ActivityStatCard(
                        icon: "arrow.up.right",
                        title: "Hoogtemeters",
                        value: activityTracker.currentActivity?.formattedElevation ?? "0 m",
                        color: .purple
                    )
                    
                    // Control Buttons
                    HStack(spacing: 16) {
                        if activityTracker.isPaused {
                            Button(action: {
                                activityTracker.resumeActivity()
                            }) {
                                Label("Hervat", systemImage: "play.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                        } else {
                            Button(action: {
                                activityTracker.pauseActivity()
                            }) {
                                Label("Pauzeer", systemImage: "pause.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange)
                                    .cornerRadius(12)
                            }
                        }
                        
                        Button(action: {
                            activityTracker.stopActivity()
                        }) {
                            Label("Stop", systemImage: "stop.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
        }
    }
    
    // MARK: - Inactive View
    
    private var inactiveView: some View {
        VStack(spacing: 24) {
            // Statistics Overview
            VStack(spacing: 16) {
                Text("Jouw Statistieken")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(spacing: 16) {
                    OverviewStatCard(
                        title: "Totale Afstand",
                        value: activityTracker.statistics.formattedTotalDistance,
                        icon: "arrow.left.and.right"
                    )
                    
                    OverviewStatCard(
                        title: "Totale Tijd",
                        value: activityTracker.statistics.formattedTotalTime,
                        icon: "clock.fill"
                    )
                }
                
                HStack(spacing: 16) {
                    OverviewStatCard(
                        title: "Activiteiten",
                        value: "\(activityTracker.statistics.totalActivities)",
                        icon: "list.bullet"
                    )
                    
                    OverviewStatCard(
                        title: "Gem. Snelheid",
                        value: String(format: "%.1f km/h", activityTracker.statistics.avgSpeed),
                        icon: "speedometer"
                    )
                }
            }
            .padding()
            
            Spacer()
            
            // Start Activity Button
            Button(action: {
                showingStartActivity = true
            }) {
                Label("Start Activiteit", systemImage: "play.circle.fill")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(radius: 5)
            }
            .padding()
            
            // Recent Activities
            if !activityTracker.activities.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recente Activiteiten")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(Array(activityTracker.activities.prefix(3))) { activity in
                        ActivityRowCompact(activity: activity)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedActivity = activity
                            }
                    }
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Activity Stat Card

struct ActivityStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Overview Stat Card

struct OverviewStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Activity Row Compact

struct ActivityRowCompact: View {
    let activity: CyclingActivity
    
    var body: some View {
        HStack {
            Image(systemName: "bicycle")
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 50, height: 50)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.name)
                    .font(.headline)
                
                Text(activity.startDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(activity.formattedDistance)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(activity.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Activity Map View

struct ActivityMapView: View {
    let trackPoints: [TrackPoint]
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    
    var body: some View {
        Map(position: $position) {
            UserAnnotation()
        }
        .mapStyle(.standard(elevation: .realistic))
        .onAppear {
            updatePosition()
        }
    }
    
    private func updatePosition() {
        guard let lastPoint = trackPoints.last else { return }
        position = .region(MKCoordinateRegion(
            center: lastPoint.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
}

// MARK: - Start Activity View

struct StartActivityView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var activityTracker = ActivityTracker.shared
    @State private var activityName = "Fietstocht"
    @State private var selectedBikeType: BikeType = .city
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Activiteit Details") {
                    TextField("Naam", text: $activityName)
                    
                    Picker("Fietstype", selection: $selectedBikeType) {
                        ForEach(BikeType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
                
                Section {
                    Button(action: startActivity) {
                        Label("Start Activiteit", systemImage: "play.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Nieuwe Activiteit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuleer") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func startActivity() {
        activityTracker.startActivity(name: activityName, bikeType: selectedBikeType)
        dismiss()
    }
}

// MARK: - Activity List View

struct ActivityListView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var activityTracker = ActivityTracker.shared
    @State private var selectedActivity: CyclingActivity?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(activityTracker.activities) { activity in
                    Button {
                        selectedActivity = activity
                    } label: {
                        ActivityListRow(activity: activity)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            activityTracker.deleteActivity(activity)
                        } label: {
                            Label("Verwijder", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Alle Activiteiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sluiten") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedActivity) { activity in
                ActivityDetailView(activity: activity)
            }
        }
    }
}

// MARK: - Activity List Row

struct ActivityListRow: View {
    let activity: CyclingActivity
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.name)
                    .font(.headline)
                
                Text(activity.startDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Label(activity.formattedDistance, systemImage: "arrow.left.and.right")
                    Label(activity.formattedDuration, systemImage: "clock")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Activity Detail View

struct ActivityDetailView: View {
    @Environment(\.dismiss) var dismiss
    let activity: CyclingActivity
    @State private var showingShareSheet = false
    @State private var gpxString = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text(activity.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(activity.startDate, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        DetailStatCard(icon: "arrow.left.and.right", title: "Afstand", value: activity.formattedDistance, color: .green)
                        DetailStatCard(icon: "clock", title: "Tijd", value: activity.formattedDuration, color: .blue)
                        DetailStatCard(icon: "speedometer", title: "Gem. Snelheid", value: activity.formattedAvgSpeed, color: .orange)
                        DetailStatCard(icon: "bolt.fill", title: "Max Snelheid", value: String(format: "%.1f km/h", activity.maxSpeed), color: .red)
                        DetailStatCard(icon: "arrow.up.right", title: "Hoogtemeters", value: activity.formattedElevation, color: .purple)
                        DetailStatCard(icon: "flame.fill", title: "Calorieën", value: activity.formattedCalories, color: .orange)
                    }
                    .padding()
                    
                    // Export Button
                    Button(action: exportGPX) {
                        Label("Exporteer als GPX", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Activiteit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sluiten") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [gpxString])
            }
        }
    }
    
    private func exportGPX() {
        gpxString = ActivityTracker.shared.exportToGPX(activity: activity)
        showingShareSheet = true
    }
}

// MARK: - Detail Stat Card

struct DetailStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Share Sheet (if not already defined elsewhere)
#if !SHARESHEET_DEFINED
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

#Preview {
    ActivityTrackingView()
}

