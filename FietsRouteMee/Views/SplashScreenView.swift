//
//  SplashScreenView.swift
//  FietsRouteMee
//
//  Modern iOS 2025 Splash Screen met animaties
//

import SwiftUI

struct SplashScreenView: View {
    @Binding var showSplash: Bool
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    
    // Version info - Hardcoded for splash screen display
    private var appVersion: String {
        "1.0.0"
    }
    
    private var buildNumber: String {
        "202510191346"
    }
    
    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.8, blue: 0.4),  // Fresh green
                    Color(red: 0.1, green: 0.6, blue: 0.3)   // Deep green
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App Icon - Centraal en groot met iOS 26 effecten
                ZStack {
                    // Outer glow ring - iOS 26 style
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    .white.opacity(0.4),
                                    .green.opacity(0.3),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 80,
                                endRadius: 160
                            )
                        )
                        .frame(width: 400, height: 400)
                        .blur(radius: 35)
                    
                    // Inner glow - Vibrant
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.5), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 120
                            )
                        )
                        .frame(width: 320, height: 320)
                        .blur(radius: 30)
                    
                    // Liquid Glass container - iOS 26
                    ZStack {
                        // Glass background with tint
                        RoundedRectangle(cornerRadius: 56, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 56, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(0.3),
                                                .white.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                // Highlight effect - iOS 26 Liquid Glass
                                RoundedRectangle(cornerRadius: 56, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(0.6),
                                                .white.opacity(0.2),
                                                .clear
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                            .frame(width: 300, height: 300)
                        
                        // App Icon - Even Larger!
                        Image("SplashIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 280, height: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 60, style: .continuous))
                            .overlay(
                                // Subtle inner shadow for depth
                                RoundedRectangle(cornerRadius: 60, style: .continuous)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                .black.opacity(0.1),
                                                .clear
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .shadow(color: .black.opacity(0.3), radius: 30, y: 15)
                    .shadow(color: .green.opacity(0.5), radius: 20, y: 10)
                }
                .scaleEffect(scale)
                .opacity(opacity)
                .rotation3DEffect(
                    .degrees(scale < 1 ? 15 : 0),
                    axis: (x: 1, y: 1, z: 0)
                )
                
                // App Name - iOS 26 Glassmorphism
                VStack(spacing: 16) {
                    Text("FietsRouteMee")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                        .shadow(color: .green.opacity(0.5), radius: 12, y: 6)
                    
                    // Subtitle with glass effect
                    Text("Jouw Fietsroute Planner")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.95))
                        .tracking(2)
                        .textCase(.uppercase)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    .white.opacity(0.4),
                                                    .white.opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                }
                .opacity(textOpacity)
                
                Spacer()
                
                // Creator & Version Info
                VStack(spacing: 16) {
                    // Divider
                    Rectangle()
                        .fill(.white.opacity(0.3))
                        .frame(width: 60, height: 2)
                        .clipShape(Capsule())
                    
                    VStack(spacing: 8) {
                        Text("Ontwikkeld door")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.8))
                            .textCase(.uppercase)
                            .tracking(1.5)
                        
                        Text("Cor Meskers")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                    
                    // Version Info
                    HStack(spacing: 8) {
                        Text("Versie \(appVersion)")
                        Text("•")
                        Text("Build \(buildNumber)")
                    }
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.7))
                    .tracking(1)
                }
                .opacity(textOpacity)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            print("🚀 SplashScreen: Started")
            
            // iOS 26 style - Elegant animation sequence with 3D effect
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7, blendDuration: 0.3)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Text fade in with delay for elegant reveal
            withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
                textOpacity = 1.0
            }
            
            // Auto-dismiss after 4.5 seconds (longer for better branding)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                print("🚀 SplashScreen: Starting fade out")
                
                // iOS 26 style - Smooth zoom out with bounce
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    scale = 1.15
                }
                
                withAnimation(.easeOut(duration: 0.6)) {
                    opacity = 0.0
                    textOpacity = 0.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    print("🚀 SplashScreen: Dismissing - Setting showSplash to false")
                    showSplash = false
                }
            }
        }
    }
}

#Preview {
    SplashScreenView(showSplash: .constant(true))
}

