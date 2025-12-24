//
//  ContentView.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        ZStack {
            Color.tymerBlack
                .ignoresSafeArea()
            
            // Router principal
            Group {
                switch appState.currentScreen {
                case .splash:
                    SplashView {
                        handleSplashComplete()
                    }
                    .transition(.opacity)
                    
                case .onboarding:
                    OnboardingView {
                        handleOnboardingComplete()
                    }
                    .transition(.move(edge: .trailing))
                    
                case .gate:
                    GateView()
                        .transition(.opacity)
                    
                case .feed:
                    FeedView()
                        .transition(.move(edge: .bottom))
                    
                case .capture:
                    CaptureView()
                        .transition(.move(edge: .bottom))
                    
                case .circle:
                    CircleView()
                        .transition(.move(edge: .leading))
                    
                case .digest:
                    DigestView()
                        .transition(.move(edge: .trailing))
                    
                case .messages:
                    MessageView()
                        .transition(.move(edge: .top))
                    
                case .momentDetail:
                    // Pour une future implémentation détaillée
                    FeedView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: appState.currentScreen)
        }
    }
    
    // MARK: - Navigation Handlers
    
    private func handleSplashComplete() {
        if appState.hasCompletedOnboarding {
            appState.navigate(to: .gate)
        } else {
            appState.navigate(to: .onboarding)
        }
    }
    
    private func handleOnboardingComplete() {
        appState.hasCompletedOnboarding = true
        appState.navigate(to: .gate)
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
