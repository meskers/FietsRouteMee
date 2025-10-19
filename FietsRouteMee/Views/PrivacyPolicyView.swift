//
//  PrivacyPolicyView.swift
//  FietsRouteMee
//
//  Volledig werkende Privacy Policy view
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Privacy Beleid")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Laatst bijgewerkt: \(formattedDate)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Divider()
                
                PolicySection(
                    title: "Welke gegevens verzamelen we?",
                    content: """
                    FietsRouteMee verzamelt de volgende gegevens:
                    
                    • Locatiegegevens: Voor route planning en navigatie
                    • Routes en favorieten: Opgeslagen op jouw apparaat
                    • App gebruik: Alleen als je analytics hebt ingeschakeld
                    • Crash reports: Om de app te verbeteren
                    
                    Al je gegevens blijven lokaal op jouw apparaat en worden niet gedeeld zonder jouw toestemming.
                    """
                )
                
                PolicySection(
                    title: "Hoe gebruiken we je gegevens?",
                    content: """
                    We gebruiken je gegevens voor:
                    
                    • Het berekenen en tonen van fietsroutes
                    • Het opslaan van je favoriete routes
                    • Het verbeteren van de app ervaring
                    • Het geven van turn-by-turn navigatie
                    
                    Je gegevens worden NOOIT verkocht aan derden.
                    """
                )
                
                PolicySection(
                    title: "Je rechten",
                    content: """
                    Je hebt het recht om:
                    
                    • Al je gegevens in te zien
                    • Je gegevens te exporteren
                    • Al je gegevens te verwijderen
                    • Je privacy instellingen aan te passen
                    
                    Dit kan je doen via de Privacy instellingen in de app.
                    """
                )
                
                PolicySection(
                    title: "Data beveiliging",
                    content: """
                    We nemen je privacy serieus:
                    
                    • Alle data wordt lokaal opgeslagen
                    • Routes worden versleuteld opgeslagen
                    • Geen tracking zonder toestemming
                    • Volledige controle over je data
                    """
                )
                
                PolicySection(
                    title: "Contact",
                    content: """
                    Vragen over je privacy? Neem contact op via:
                    
                    Email: privacy@fietsroutemee.nl
                    Website: www.fietsroutemee.nl
                    
                    We reageren binnen 48 uur op je verzoek.
                    """
                )
            }
            .padding()
        }
        .navigationTitle("Privacy Beleid")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "nl_NL")
        return formatter.string(from: Date())
    }
}

struct PolicySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(content)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}

