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
            
            // Router principal avec animations fluides
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
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .opacity
                    ))
                    
                case .gate:
                    GateView()
                        .transition(.opacity)
                    
                case .feed:
                    FeedView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                    
                case .capture:
                    CaptureView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                    
                case .circle:
                    CircleView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading),
                            removal: .move(edge: .leading)
                        ))
                    
                case .digest:
                    DigestView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .trailing)
                        ))
                    
                case .messages:
                    MessageView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                    
                case .momentDetail:
                    FeedView()
                        .transition(.opacity)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: appState.currentScreen)
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
