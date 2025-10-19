//
//  CollectionsView.swift
//  FietsRouteMee
//
//  Komoot-style Collections
//

import SwiftUI

struct CollectionsView: View {
    @StateObject private var collectionsManager = CollectionsManager.shared
    @StateObject private var routeManager = RouteManager.shared
    @State private var showingCreateCollection = false
    @State private var selectedCollection: RouteCollection?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Create Collection Button
                    Button(action: {
                        showingCreateCollection = true
                    }) {
                        Label("Nieuwe Collectie", systemImage: "plus.circle.fill")
                            .font(.headline)
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
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Collections Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(collectionsManager.collections) { collection in
                            CollectionCard(collection: collection)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedCollection = collection
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Collecties")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingCreateCollection) {
                CreateCollectionView()
            }
            .sheet(item: $selectedCollection) { collection in
                CollectionDetailView(collection: collection)
            }
        }
    }
}

// MARK: - Collection Card

struct CollectionCard: View {
    let collection: RouteCollection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Cover Image or Color
            if let imageData = collection.coverImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
            } else {
                Rectangle()
                    .fill(collection.colorValue)
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "map.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.5))
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("\(collection.routeCount) routes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Create Collection View

struct CreateCollectionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var collectionsManager = CollectionsManager.shared
    @State private var name = ""
    @State private var description = ""
    @State private var selectedColor = Color.blue
    
    let colorOptions: [Color] = [.blue, .green, .orange, .red, .purple, .pink, .indigo, .teal]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Naam", text: $name)
                    TextField("Beschrijving", text: $description)
                }
                
                Section("Kleur") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(colorOptions, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                }
                
                Section {
                    Button(action: createCollection) {
                        Text("Aanmaken")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(name.isEmpty)
                }
            }
            .navigationTitle("Nieuwe Collectie")
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
    
    private func createCollection() {
        let collection = RouteCollection(
            name: name,
            description: description,
            color: selectedColor.toHex()
        )
        collectionsManager.createCollection(collection)
        dismiss()
    }
}

// MARK: - Collection Detail View

struct CollectionDetailView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var collectionsManager = CollectionsManager.shared
    @StateObject private var routeManager = RouteManager.shared
    @State private var showingAddRoute = false
    let collection: RouteCollection
    
    var collectionRoutes: [BikeRoute] {
        routeManager.routes.filter { collection.routeIDs.contains($0.id) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(collection.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Section("Routes (\(collectionRoutes.count))") {
                    if collectionRoutes.isEmpty {
                        Text("Geen routes in deze collectie")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(collectionRoutes, id: \.id) { (route: BikeRoute) in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Fietsroute")
                                    .font(.headline)
                                    .foregroundStyle(Color.primary)
                                
                                HStack {
                                    Label(String(format: "%.1f km", route.distance / 1000), systemImage: "arrow.left.and.right")
                                    Label(String(format: "%.0f min", route.duration / 60), systemImage: "clock")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    collectionsManager.removeRouteFromCollection(routeID: route.id, collectionID: collection.id)
                                } label: {
                                    Label("Verwijder", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button {
                        showingAddRoute = true
                    } label: {
                        Label("Route Toevoegen", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle(collection.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sluiten") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddRoute) {
                AddRouteToCollectionView(collection: collection)
            }
        }
    }
}

// MARK: - Add Route to Collection View

struct AddRouteToCollectionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var collectionsManager = CollectionsManager.shared
    @StateObject private var routeManager = RouteManager.shared
    let collection: RouteCollection
    
    var availableRoutes: [BikeRoute] {
        routeManager.routes.filter { !collection.routeIDs.contains($0.id) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if availableRoutes.isEmpty {
                    Text("Geen routes beschikbaar")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(availableRoutes, id: \.id) { (route: BikeRoute) in
                        Button {
                            collectionsManager.addRouteToCollection(routeID: route.id, collectionID: collection.id)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Fietsroute")
                                    .font(.headline)
                                    .foregroundStyle(Color.primary)
                                
                                HStack {
                                    Label(String(format: "%.1f km", route.distance / 1000), systemImage: "arrow.left.and.right")
                                    Label(String(format: "%.0f min", route.duration / 60), systemImage: "clock")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Route Toevoegen")
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
}

#Preview {
    CollectionsView()
}

