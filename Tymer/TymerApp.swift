//
//  TymerApp.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI

@main
struct TymerApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(appState)
                    .preferredColorScheme(.dark)

                // Invitation acceptance overlay
                InviteAcceptanceOverlay()
                    .environment(appState)
            }
            .onOpenURL { url in
                appState.handleDeepLink(url)
            }
        }
    }
}

// MARK: - Invite Acceptance Overlay
struct InviteAcceptanceOverlay: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            switch appState.inviteAcceptanceState {
            case .none:
                EmptyView()

            case .processing:
                overlayCard {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.tymerWhite)

                        Text("Acceptation de l'invitation...")
                            .font(.funnelSemiBold(16))
                            .foregroundColor(.tymerWhite)
                    }
                }

            case .success(let friendName):
                overlayCard {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)

                        Text("\(friendName) a rejoint ton cercle !")
                            .font(.funnelSemiBold(16))
                            .foregroundColor(.tymerWhite)
                            .multilineTextAlignment(.center)
                    }
                }

            case .error(let message):
                overlayCard {
                    VStack(spacing: 16) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.red)

                        Text(message)
                            .font(.funnelSemiBold(14))
                            .foregroundColor(.tymerWhite)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.inviteAcceptanceState)
    }

    private func overlayCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack {
                content()
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.tymerBlack)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.tymerDarkGray, lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 20)
        }
        .transition(.opacity)
    }
}
