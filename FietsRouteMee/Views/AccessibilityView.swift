//
//  AccessibilityView.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 18/10/2025.
//

import SwiftUI

struct AccessibilityView: View {
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // System Accessibility Status
                Section("Systeem Toegankelijkheid") {
                    AccessibilityStatusRow(
                        title: "VoiceOver",
                        isEnabled: accessibilityManager.isVoiceOverEnabled,
                        icon: "eye.fill"
                    )
                    
                    AccessibilityStatusRow(
                        title: "Beweging Verminderen",
                        isEnabled: accessibilityManager.isReduceMotionEnabled,
                        icon: "slowmo"
                    )
                    
                    AccessibilityStatusRow(
                        title: "Transparantie Verminderen",
                        isEnabled: accessibilityManager.isReduceTransparencyEnabled,
                        icon: "square.stack.3d.up.fill"
                    )
                    
                    AccessibilityStatusRow(
                        title: "Donkere Systeemkleuren",
                        isEnabled: accessibilityManager.isDarkerSystemColorsEnabled,
                        icon: "paintbrush.fill"
                    )
                    
                    AccessibilityStatusRow(
                        title: "Knop Vormen",
                        isEnabled: accessibilityManager.isButtonShapesEnabled,
                        icon: "rectangle.fill"
                    )
                    
                    AccessibilityStatusRow(
                        title: "Aan/Uit Labels",
                        isEnabled: accessibilityManager.isOnOffLabelsEnabled,
                        icon: "textformat.abc"
                    )
                }
                
                // Custom Accessibility Settings
                Section("App Toegankelijkheid") {
                    Toggle("Hoge Contrast Modus", isOn: $accessibilityManager.highContrastMode)
                        .onChange(of: accessibilityManager.highContrastMode) {
                            accessibilityManager.setHighContrastMode(accessibilityManager.highContrastMode)
                        }
                        .accessibilityLabel("Hoge contrast modus")
                        .accessibilityHint("Verhoogt het contrast voor betere leesbaarheid")
                    
                    Toggle("Grote Tekst", isOn: $accessibilityManager.largeTextSize)
                        .onChange(of: accessibilityManager.largeTextSize) {
                            accessibilityManager.setLargeTextSize(accessibilityManager.largeTextSize)
                        }
                        .accessibilityLabel("Grote tekst")
                        .accessibilityHint("Vergroot de tekst voor betere leesbaarheid")
                    
                    Toggle("Spraaknavigatie", isOn: $accessibilityManager.voiceNavigationEnabled)
                        .onChange(of: accessibilityManager.voiceNavigationEnabled) {
                            accessibilityManager.setVoiceNavigationEnabled(accessibilityManager.voiceNavigationEnabled)
                        }
                        .accessibilityLabel("Spraaknavigatie")
                        .accessibilityHint("Schakelt spraaknavigatie in voor routes")
                    
                    Toggle("Trilfeedback", isOn: $accessibilityManager.hapticFeedbackEnabled)
                        .onChange(of: accessibilityManager.hapticFeedbackEnabled) {
                            accessibilityManager.setHapticFeedbackEnabled(accessibilityManager.hapticFeedbackEnabled)
                        }
                        .accessibilityLabel("Trilfeedback")
                        .accessibilityHint("Schakelt trillingen in voor feedback")
                    
                    Toggle("Audiocues", isOn: $accessibilityManager.audioCuesEnabled)
                        .onChange(of: accessibilityManager.audioCuesEnabled) {
                            accessibilityManager.setAudioCuesEnabled(accessibilityManager.audioCuesEnabled)
                        }
                        .accessibilityLabel("Audiocues")
                        .accessibilityHint("Schakelt geluiden in voor feedback")
                }
                
                // Accessibility Features
                Section("Toegankelijkheidsfuncties") {
                    NavigationLink(destination: VoiceOverHelpView()) {
                        HStack {
                            Image(systemName: "eye.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("VoiceOver Hulp")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("Leer hoe je VoiceOver gebruikt met deze app")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .accessibilityLabel("VoiceOver hulp")
                    .accessibilityHint("Opent hulp voor VoiceOver gebruikers")
                    
                    NavigationLink(destination: SwitchControlHelpView()) {
                        HStack {
                            Image(systemName: "switch.2")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Switch Control Hulp")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("Leer hoe je Switch Control gebruikt met deze app")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .accessibilityLabel("Switch Control hulp")
                    .accessibilityHint("Opent hulp voor Switch Control gebruikers")
                    
                    NavigationLink(destination: AccessibilityShortcutsView()) {
                        HStack {
                            Image(systemName: "command.circle.fill")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Toegankelijkheids Snelkoppelingen")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("Bekijk beschikbare snelkoppelingen")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .accessibilityLabel("Toegankelijkheids snelkoppelingen")
                    .accessibilityHint("Opent overzicht van snelkoppelingen")
                }
                
                // Accessibility Testing
                Section("Toegankelijkheid Testen") {
                    Button("Test VoiceOver Aankondiging") {
                        accessibilityManager.announce("Dit is een test van de VoiceOver aankondiging functie.")
                    }
                    .accessibilityLabel("Test VoiceOver aankondiging")
                    .accessibilityHint("Test of VoiceOver aankondigingen werken")
                    
                    Button("Test Trilfeedback") {
                        accessibilityManager.playHapticFeedback(.success)
                    }
                    .accessibilityLabel("Test trilfeedback")
                    .accessibilityHint("Test of trilfeedback werkt")
                    
                    Button("Test Audiocue") {
                        accessibilityManager.playAudioCue(.success)
                    }
                    .accessibilityLabel("Test audiocue")
                    .accessibilityHint("Test of audiocues werken")
                }
            }
            .navigationTitle("Toegankelijkheid")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Gereed") {
                        dismiss()
                    }
                    .accessibilityLabel("Sluit toegankelijkheidsinstellingen")
                }
            }
        }
        .onAppear {
            // Announce when the view appears for VoiceOver users
            accessibilityManager.announce("Toegankelijkheidsinstellingen geopend")
        }
    }
}

// MARK: - Accessibility Status Row

struct AccessibilityStatusRow: View {
    let title: String
    let isEnabled: Bool
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isEnabled ? .green : .secondary)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            if isEnabled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .accessibilityLabel("Ingeschakeld")
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Uitgeschakeld")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(isEnabled ? "ingeschakeld" : "uitgeschakeld")")
    }
}

// MARK: - VoiceOver Help View

struct VoiceOverHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section("VoiceOver Basis") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("VoiceOver is een schermlezer die tekst en elementen hardop voorleest.")
                        .font(.body)
                    
                    Text("• Veeg met één vinger om te navigeren")
                    Text("• Tik dubbel om te activeren")
                    Text("• Veeg met drie vingers om te scrollen")
                    Text("• Draai met twee vingers om de rotor te gebruiken")
                }
                .padding(.vertical, 8)
            }
            
            Section("App Specifieke Tips") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("In deze app kun je:")
                        .font(.body)
                    
                    Text("• Routes verkennen door te vegen")
                    Text("• Route details beluisteren")
                    Text("• Navigatie instructies horen")
                    Text("• Instellingen aanpassen met VoiceOver")
                }
                .padding(.vertical, 8)
            }
            
            Section("Snelkoppelingen") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("• Dubbel tik om een route te starten")
                    Text("• Veeg omhoog/omlaag om tussen tabs te wisselen")
                    Text("• Gebruik de rotor voor snelle navigatie")
                    Text("• Dubbel tik en houd vast voor context menu's")
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("VoiceOver Hulp")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Gereed") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Switch Control Help View

struct SwitchControlHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section("Switch Control Basis") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Switch Control laat je de app bedienen met externe switches.")
                        .font(.body)
                    
                    Text("• Gebruik je switch om door elementen te navigeren")
                    Text("• Activeer elementen door je switch te activeren")
                    Text("• Gebruik de scanner om door de interface te bewegen")
                }
                .padding(.vertical, 8)
            }
            
            Section("App Navigatie") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("In deze app kun je:")
                        .font(.body)
                    
                    Text("• Routes selecteren en starten")
                    Text("• Tussen verschillende tabs wisselen")
                    Text("• Instellingen aanpassen")
                    Text("• Navigatie instructies volgen")
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Switch Control Hulp")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Gereed") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Accessibility Shortcuts View

struct AccessibilityShortcutsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section("Algemene Snelkoppelingen") {
                ShortcutRow(
                    shortcut: "Cmd + R",
                    description: "Route starten",
                    icon: "play.fill"
                )
                
                ShortcutRow(
                    shortcut: "Cmd + S",
                    description: "Route stoppen",
                    icon: "stop.fill"
                )
                
                ShortcutRow(
                    shortcut: "Cmd + M",
                    description: "Kaart centreren",
                    icon: "location.fill"
                )
                
                ShortcutRow(
                    shortcut: "Cmd + T",
                    description: "Tab wisselen",
                    icon: "rectangle.stack.fill"
                )
            }
            
            Section("VoiceOver Snelkoppelingen") {
                ShortcutRow(
                    shortcut: "Ctrl + Opt + H",
                    description: "VoiceOver hulp",
                    icon: "questionmark.circle.fill"
                )
                
                ShortcutRow(
                    shortcut: "Ctrl + Opt + L",
                    description: "Element label lezen",
                    icon: "textformat.abc"
                )
                
                ShortcutRow(
                    shortcut: "Ctrl + Opt + R",
                    description: "Rotor gebruiken",
                    icon: "rotate.3d.fill"
                )
            }
            
            Section("Switch Control Snelkoppelingen") {
                ShortcutRow(
                    shortcut: "Switch 1",
                    description: "Volgende element",
                    icon: "arrow.right.circle.fill"
                )
                
                ShortcutRow(
                    shortcut: "Switch 2",
                    description: "Element activeren",
                    icon: "hand.tap.fill"
                )
                
                ShortcutRow(
                    shortcut: "Switch 3",
                    description: "Menu openen",
                    icon: "list.bullet.circle.fill"
                )
            }
        }
        .navigationTitle("Snelkoppelingen")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Gereed") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Shortcut Row

struct ShortcutRow: View {
    let shortcut: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(shortcut)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(description): \(shortcut)")
    }
}

#Preview {
    AccessibilityView()
}
