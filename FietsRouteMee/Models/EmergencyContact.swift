//
//  EmergencyContact.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 16/10/2025.
//

import Foundation
import Combine

struct EmergencyContact: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var phoneNumber: String
    var email: String?
    var relationship: String?
    var createdAt: Date
    
    init(name: String, phoneNumber: String, email: String? = nil, relationship: String? = nil) {
        self.id = UUID()
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.relationship = relationship
        self.createdAt = Date()
    }
}

class EmergencyContactsManager: ObservableObject {
    @Published var emergencyContacts: [EmergencyContact] = []
    @Published var isTrackingEnabled: Bool {
        didSet { 
            UserDefaults.standard.set(isTrackingEnabled, forKey: "tracking_enabled")
            print("🔒 Tracking enabled: \(isTrackingEnabled)")
        }
    }
    @Published var shareWithFriends: Bool {
        didSet { 
            UserDefaults.standard.set(shareWithFriends, forKey: "share_with_friends")
        }
    }
    
    private let contactsKey = "emergency_contacts"
    
    init() {
        self.isTrackingEnabled = UserDefaults.standard.bool(forKey: "tracking_enabled")
        self.shareWithFriends = UserDefaults.standard.bool(forKey: "share_with_friends")
        loadContacts()
    }
    
    func addContact(_ contact: EmergencyContact) {
        emergencyContacts.append(contact)
        saveContacts()
        print("✅ Emergency contact added: \(contact.name)")
    }
    
    func removeContact(_ contact: EmergencyContact) {
        emergencyContacts.removeAll { $0.id == contact.id }
        saveContacts()
        print("🗑️ Emergency contact removed: \(contact.name)")
    }
    
    func updateContact(_ contact: EmergencyContact) {
        if let index = emergencyContacts.firstIndex(where: { $0.id == contact.id }) {
            emergencyContacts[index] = contact
            saveContacts()
            print("✏️ Emergency contact updated: \(contact.name)")
        }
    }
    
    private func saveContacts() {
        if let encoded = try? JSONEncoder().encode(emergencyContacts) {
            UserDefaults.standard.set(encoded, forKey: contactsKey)
            print("💾 Saved \(emergencyContacts.count) emergency contacts")
        }
    }
    
    private func loadContacts() {
        if let data = UserDefaults.standard.data(forKey: contactsKey),
           let decoded = try? JSONDecoder().decode([EmergencyContact].self, from: data) {
            emergencyContacts = decoded
            print("📱 Loaded \(emergencyContacts.count) emergency contacts")
        }
    }
    
    func clearAllContacts() {
        emergencyContacts.removeAll()
        saveContacts()
    }
}

