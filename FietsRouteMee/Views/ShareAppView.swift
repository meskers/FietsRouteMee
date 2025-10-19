//
//  ShareAppView.swift
//  FietsRouteMee
//
//  Volledig werkende app delen functionaliteit
//

import SwiftUI

struct ShareAppView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // App Icon
                Image(systemName: "bicycle.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(
                        LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                VStack(spacing: 16) {
                    Text("Deel FietsRouteMee")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Vertel je vrienden over deze geweldige fiets app!")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                VStack(spacing: 12) {
                    ShareButton(
                        title: "Deel via Berichten",
                        icon: "message.fill",
                        color: .green
                    ) {
                        shareViaMessages()
                    }
                    
                    ShareButton(
                        title: "Deel via Social Media",
                        icon: "square.and.arrow.up",
                        color: .blue
                    ) {
                        shareViaSheet()
                    }
                    
                    ShareButton(
                        title: "Kopieer Link",
                        icon: "doc.on.doc",
                        color: .purple
                    ) {
                        copyAppLink()
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical, 32)
            .navigationTitle("Delen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sluiten") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func shareViaMessages() {
        let text = "Probeer FietsRouteMee! De beste app voor fietsroutes in Nederland. Download nu in de App Store!"
        
        if let url = URL(string: "sms:&body=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }
    
    private func shareViaSheet() {
        let text = "Probeer FietsRouteMee! De beste app voor fietsroutes in Nederland."
        let url = URL(string: "https://www.fietsroutemee.nl")!
        
        let activityVC = UIActivityViewController(
            activityItems: [text, url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func copyAppLink() {
        UIPasteboard.general.string = "https://www.fietsroutemee.nl"
        
        // Show confirmation with haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        print("✅ Share: App link copied to clipboard")
    }
}

struct ShareButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(color)
        }
    }
}

#Preview {
    ShareAppView()
}

