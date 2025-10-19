//
//  ContentView.swift
//  FietsRouteMee
//
//  Created by Cor Meskers on 08/10/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                // SplashScreenView is defined in Views/SplashScreenView.swift
                // This is a Cursor indexer issue - the view exists and compiles correctly
                SplashScreenView(showSplash: $showSplash)
                    .transition(.opacity)
                    .zIndex(1)
            } else {
                // MainTabView is defined in Views/MainTabView.swift  
                // This is a Cursor indexer issue - the view exists and compiles correctly
                MainTabView()
                    .transition(.opacity)
                    .zIndex(0)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showSplash)
        .onChange(of: showSplash) { oldValue, newValue in
            print("📱 ContentView: showSplash changed from \(oldValue) to \(newValue)")
        }
    }
}

#Preview {
    ContentView()
}
