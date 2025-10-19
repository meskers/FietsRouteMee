//
//  RouteOptionsView.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 08/10/2025.
//

import SwiftUI

struct RouteOptionsView: View {
    @ObservedObject var routeManager: RouteManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Tab", selection: $selectedTab) {
                    Text("Algemeen").tag(0)
                    Text("Live Tracking").tag(1)
                    Text("Privacy").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    GeneralSettingsTab()
                        .tag(0)
                    
                    LiveTrackingTab()
                        .tag(1)
                    
                    PrivacyTab()
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Route Opties")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Gereed") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct GeneralSettingsTab: View {
    @ObservedObject private var settingsManager = AppSettingsManager.shared
    
    var body: some View {
        Form {
            Section("Fietstype") {
                Picker("Standaard fietstype", selection: $settingsManager.selectedBikeType) {
                    ForEach(BikeType.allCases, id: \.self) { type in
                        HStack {
                            Image(systemName: type.icon)
                            Text(type.displayName)
                        }
                        .tag(type)
                    }
                }
                .pickerStyle(.navigationLink)
                
                Text("Dit fietstype wordt gebruikt voor alle nieuwe routes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Route Voorkeuren") {
                Toggle("Vermijd snelwegen", isOn: $settingsManager.avoidHighways)
                Toggle("Vermijd tunnels", isOn: $settingsManager.avoidTunnels)
                Toggle("Voorkeur fietspaden", isOn: $settingsManager.preferBikePaths)
                Toggle("Voorkeur natuur", isOn: $settingsManager.preferNature)
            }
            
            Section("Limieten") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Maximale afstand")
                        Spacer()
                        Text("\(Int(settingsManager.maxDistance)) km")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $settingsManager.maxDistance, in: 5...100, step: 5)
                        .tint(.green)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Maximale hoogte")
                        Spacer()
                        Text("\(Int(settingsManager.maxElevation)) m")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $settingsManager.maxElevation, in: 50...500, step: 25)
                        .tint(.green)
                }
            }
            
            Section {
                Text("Deze instellingen worden automatisch toegepast op alle nieuwe routes die je plant.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct LiveTrackingTab: View {
    @StateObject private var contactsManager = EmergencyContactsManager()
    @State private var showingAddContact = false
    @State private var newContactName = ""
    @State private var newContactPhone = ""
    @State private var showingDeleteAlert = false
    @State private var contactToDelete: EmergencyContact?
    
    var body: some View {
        Form {
            Section("Live Tracking") {
                Toggle("Tracking inschakelen", isOn: $contactsManager.isTrackingEnabled)
                
                if contactsManager.isTrackingEnabled {
                    Toggle("Delen met vrienden", isOn: $contactsManager.shareWithFriends)
                }
            }
            
            Section {
                if contactsManager.emergencyContacts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.slash")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        
                        Text("Geen noodcontacten")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Voeg contacten toe die gewaarschuwd worden in geval van nood")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    ForEach(contactsManager.emergencyContacts) { contact in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(contact.name)
                                    .font(.headline)
                                
                                Text(contact.phoneNumber)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                // In real app, this would open phone
                                print("📞 Calling \(contact.name)")
                            }) {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.green)
                            }
                            .buttonStyle(.plain)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                contactToDelete = contact
                                showingDeleteAlert = true
                            } label: {
                                Label("Verwijder", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                Text("Noodcontacten")
            } footer: {
                Text("Deze contacten worden automatisch gewaarschuwd als je een noodmelding activeert tijdens het fietsen")
                    .font(.caption)
            }
            
            Section {
                Button(action: {
                    showingAddContact = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                        Text("Contact toevoegen")
                            .foregroundColor(.primary)
                    }
                }
            }
            
            Section("Privacy") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.blue)
                        Text("Je locatie wordt alleen gedeeld tijdens actieve routes")
                            .font(.caption)
                    }
                    
                    HStack {
                        Image(systemName: "eye.slash.fill")
                            .foregroundColor(.blue)
                        Text("Noodcontacten worden veilig opgeslagen op je apparaat")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showingAddContact) {
            AddEmergencyContactView(contactsManager: contactsManager)
        }
        .alert("Contact verwijderen", isPresented: $showingDeleteAlert) {
            Button("Annuleren", role: .cancel) { }
            Button("Verwijder", role: .destructive) {
                if let contact = contactToDelete {
                    contactsManager.removeContact(contact)
                }
            }
        } message: {
            if let contact = contactToDelete {
                Text("Weet je zeker dat je \(contact.name) wilt verwijderen uit je noodcontacten?")
            }
        }
    }
}

struct PrivacyTab: View {
    @AppStorage("shareAnalytics") private var shareAnalytics = false
    @AppStorage("shareLocationData") private var shareLocationData = false
    @AppStorage("allowPersonalization") private var allowPersonalization = true
    
    @State private var showingDataExport = false
    @State private var showingDeleteConfirm = false
    @State private var isDeleting = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Analytische data delen", isOn: $shareAnalytics)
                    .onChange(of: shareAnalytics) { oldValue, newValue in
                        print("📊 Privacy: Analytics sharing \(newValue ? "enabled" : "disabled")")
                    }
                
                Toggle("Locatiedata delen", isOn: $shareLocationData)
                    .onChange(of: shareLocationData) { oldValue, newValue in
                        print("📍 Privacy: Location sharing \(newValue ? "enabled" : "disabled")")
                    }
                
                Toggle("Personalisatie toestaan", isOn: $allowPersonalization)
                    .onChange(of: allowPersonalization) { oldValue, newValue in
                        print("✨ Privacy: Personalization \(newValue ? "enabled" : "disabled")")
                    }
            } header: {
                Text("Data Delen")
            } footer: {
                Text("Deze instellingen bepalen welke data wordt gedeeld voor verbetering van de app. Je kunt dit op elk moment wijzigen.")
                    .font(.caption)
            }
            
            Section("Privacy Documenten") {
                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("Privacy Beleid")
                    }
                }
                
                NavigationLink {
                    TermsOfServiceView()
                } label: {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("Gebruiksvoorwaarden")
                    }
                }
            }
            
            Section {
                Button(role: .destructive) {
                    showingDeleteConfirm = true
                } label: {
                    HStack {
                        if isDeleting {
                            ProgressView()
                        } else {
                            Image(systemName: "trash")
                            Text("Alle data verwijderen")
                        }
                    }
                }
                .disabled(isDeleting)
                
                Button {
                    showingDataExport = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Exporteer mijn data")
                    }
                }
            } header: {
                Text("Data Beheer")
            } footer: {
                Text("Je kunt al je opgeslagen data exporteren of verwijderen. Let op: verwijderen kan niet ongedaan worden gemaakt.")
                    .font(.caption)
            }
        }
        .confirmationDialog(
            "Alle app data verwijderen?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Verwijder alles", role: .destructive) {
                deleteAllData()
            }
            Button("Annuleer", role: .cancel) { }
        } message: {
            Text("Dit verwijdert alle routes, favorieten, instellingen en offline kaarten. Deze actie kan niet ongedaan worden gemaakt.")
        }
        .sheet(isPresented: $showingDataExport) {
            DataExportView()
        }
    }
    
    private func deleteAllData() {
        isDeleting = true
        
        Task {
            // Clear all data
            await MainActor.run {
                // Reset Core Data
                CoreDataManager.shared.resetPersistentStore()
                
                // Clear UserDefaults
                if let bundleID = Bundle.main.bundleIdentifier {
                    UserDefaults.standard.removePersistentDomain(forName: bundleID)
                }
                
                print("✅ Privacy: All data deleted")
            }
            
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            
            await MainActor.run {
                isDeleting = false
            }
        }
    }
}

#Preview {
    RouteOptionsView(routeManager: RouteManager.shared)
}