//
//  AddEmergencyContactView.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 16/10/2025.
//

import SwiftUI

struct AddEmergencyContactView: View {
    @ObservedObject var contactsManager: EmergencyContactsManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var relationship = ""
    @State private var selectedRelationship: ContactRelationship = .other
    @State private var showingError = false
    @State private var errorMessage = ""
    
    enum ContactRelationship: String, CaseIterable {
        case partner = "Partner"
        case family = "Familie"
        case friend = "Vriend"
        case colleague = "Collega"
        case other = "Anders"
        
        var icon: String {
            switch self {
            case .partner: return "heart.fill"
            case .family: return "house.fill"
            case .friend: return "person.2.fill"
            case .colleague: return "briefcase.fill"
            case .other: return "person.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Contact Informatie") {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        TextField("Naam", text: $name)
                            .textContentType(.name)
                    }
                    
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.green)
                            .frame(width: 30)
                        TextField("Telefoonnummer", text: $phoneNumber)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                    }
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.orange)
                            .frame(width: 30)
                        TextField("E-mail (optioneel)", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                }
                
                Section("Relatie") {
                    Picker("Type", selection: $selectedRelationship) {
                        ForEach(ContactRelationship.allCases, id: \.self) { relation in
                            HStack {
                                Image(systemName: relation.icon)
                                Text(relation.rawValue)
                            }
                            .tag(relation)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("Dit contact wordt gewaarschuwd bij een noodmelding")
                                .font(.caption)
                        }
                        
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.blue)
                            Text("Je gegevens worden veilig opgeslagen op je apparaat")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Noodcontact Toevoegen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuleren") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Opslaan") {
                        saveContact()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .alert("Fout", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !phoneNumber.trimmingCharacters(in: .whitespaces).isEmpty &&
        phoneNumber.count >= 10
    }
    
    private func saveContact() {
        // Validate input
        guard isValid else {
            errorMessage = "Vul alle verplichte velden in"
            showingError = true
            return
        }
        
        // Format phone number (remove spaces and special characters)
        let formattedPhone = phoneNumber.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        // Validate phone number format
        guard formattedPhone.allSatisfy({ $0.isNumber || $0 == "+" }) else {
            errorMessage = "Ongeldig telefoonnummer"
            showingError = true
            return
        }
        
        // Create contact
        let contact = EmergencyContact(
            name: name.trimmingCharacters(in: .whitespaces),
            phoneNumber: formattedPhone,
            email: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespaces),
            relationship: selectedRelationship.rawValue
        )
        
        // Add to manager
        contactsManager.addContact(contact)
        
        // Dismiss
        dismiss()
    }
}

#Preview {
    AddEmergencyContactView(contactsManager: EmergencyContactsManager())
}

