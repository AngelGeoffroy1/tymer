//
//  ContentView.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @StateObject private var supabase = SupabaseManager.shared

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

                case .auth:
                    AuthView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .opacity
                        ))

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

                case .profile:
                    ProfileView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .trailing)
                        ))

                // Ces écrans ne sont plus utilisés, redirige vers gate
                case .feed, .messages, .momentDetail:
                    GateView()
                        .transition(.opacity)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: appState.currentScreen)
        }
        .onChange(of: supabase.currentSession) { _, newSession in
            // Handle auth state changes
            if newSession == nil && appState.currentScreen != .splash && appState.currentScreen != .auth {
                appState.navigate(to: .auth)
            }
        }
    }

    // MARK: - Navigation Handlers

    private func handleSplashComplete() {
        Task {
            await supabase.checkSession()

            if supabase.isAuthenticated {
                // User is logged in -> go to gate
                appState.navigate(to: .gate)
            } else {
                // User not authenticated
                if appState.hasCompletedOnboarding {
                    // Already saw onboarding -> go to auth
                    appState.navigate(to: .auth)
                } else {
                    // New user -> show onboarding first
                    appState.navigate(to: .onboarding)
                }
            }
        }
    }

    private func handleOnboardingComplete() {
        appState.hasCompletedOnboarding = true
        // After onboarding, go to auth
        appState.navigate(to: .auth)
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
