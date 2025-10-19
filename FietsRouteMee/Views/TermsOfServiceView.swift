//
//  TermsOfServiceView.swift
//  FietsRouteMee
//
//  Volledig werkende Terms of Service view
//

import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Gebruiksvoorwaarden")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Laatst bijgewerkt: \(formattedDate)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Divider()
                
                TermsSection(
                    title: "1. Acceptatie van voorwaarden",
                    content: """
                    Door FietsRouteMee te gebruiken, ga je akkoord met deze voorwaarden. Als je niet akkoord gaat, gebruik de app dan niet.
                    """
                )
                
                TermsSection(
                    title: "2. Gebruik van de app",
                    content: """
                    FietsRouteMee is bedoeld voor:
                    
                    • Het plannen van fietsroutes
                    • Navigatie tijdens het fietsen
                    • Het opslaan van favoriete routes
                    
                    Je bent verantwoordelijk voor je eigen veiligheid tijdens het fietsen. Houd je altijd aan de verkeersregels.
                    """
                )
                
                TermsSection(
                    title: "3. Verantwoordelijkheid",
                    content: """
                    FietsRouteMee is niet aansprakelijk voor:
                    
                    • Schade door gebruik van de app
                    • Onjuiste route informatie
                    • Verlies van gegevens
                    • Ongelukken tijdens het fietsen
                    
                    Gebruik de app altijd met gezond verstand en op eigen risico.
                    """
                )
                
                TermsSection(
                    title: "4. Intellectueel eigendom",
                    content: """
                    Alle rechten op de app en content zijn voorbehouden. Je mag de app niet:
                    
                    • Kopiëren of distribueren
                    • Reverse engineeren
                    • Voor commerciële doeleinden gebruiken
                    """
                )
                
                TermsSection(
                    title: "5. Wijzigingen",
                    content: """
                    We kunnen deze voorwaarden op elk moment wijzigen. Belangrijke wijzigingen worden gecommuniceerd via de app.
                    """
                )
                
                TermsSection(
                    title: "6. Contact",
                    content: """
                    Vragen over deze voorwaarden?
                    
                    Email: support@fietsroutemee.nl
                    Website: www.fietsroutemee.nl
                    """
                )
            }
            .padding()
        }
        .navigationTitle("Gebruiksvoorwaarden")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "nl_NL")
        return formatter.string(from: Date())
    }
}

struct TermsSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(content)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        TermsOfServiceView()
    }
}

