//
//  GateView.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI

struct GateView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        ZStack {
            Color.tymerBlack
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header avec navigation
                headerSection
                
                Spacer()
                
                // Contenu principal
                mainContent
                
                Spacer()
                
                // Bouton de capture (toujours disponible)
                captureSection
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    handleSwipe(value)
                }
        )
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            // Swipe hint gauche (Circle)
            VStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12))
                Text("Cercle")
                    .font(.funnelLight(10))
            }
            .foregroundColor(.tymerDarkGray)
            .onTapGesture {
                appState.navigate(to: .circle)
            }
            
            Spacer()
            
            // Logo
            Text("Tymer")
                .font(.funnelSemiBold(24))
                .foregroundColor(.tymerWhite)
            
            Spacer()
            
            // Swipe hint droite (Digest)
            VStack(spacing: 4) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                Text("Digest")
                    .font(.funnelLight(10))
            }
            .foregroundColor(.tymerDarkGray)
            .onTapGesture {
                appState.navigate(to: .digest)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    // MARK: - Main Content
    @ViewBuilder
    private var mainContent: some View {
        if appState.isWindowOpen {
            // Fenêtre ouverte
            openWindowContent
        } else {
            // Fenêtre fermée
            closedWindowContent
        }
    }
    
    private var openWindowContent: some View {
        VStack(spacing: 32) {
            // Indicateur d'ouverture
            ZStack {
                Circle()
                    .stroke(Color.tymerWhite.opacity(0.2), lineWidth: 2)
                    .frame(width: 160, height: 160)
                
                Circle()
                    .fill(Color.tymerWhite.opacity(0.05))
                    .frame(width: 140, height: 140)
                
                VStack(spacing: 8) {
                    Image(systemName: "door.left.hand.open")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(.tymerWhite)
                    
                    Text(appState.currentWindow?.label ?? "")
                        .font(.funnelLight(14))
                        .foregroundColor(.tymerGray)
                }
            }
            
            VStack(spacing: 12) {
                Text("La fenêtre est ouverte")
                    .font(.tymerSubheadline)
                    .foregroundColor(.tymerWhite)
                
                Text(appState.nextWindowCountdown)
                    .font(.tymerCaption)
                    .foregroundColor(.tymerGray)
            }
            
            // Bouton entrer
            TymerButton("Entrer", style: .primary) {
                appState.resetFeed()
                appState.navigate(to: .feed)
            }
            
            // Notifications
            if !appState.moments.isEmpty {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.tymerWhite)
                        .frame(width: 8, height: 8)
                    Text("\(appState.moments.count) moments à découvrir")
                        .font(.funnelLight(14))
                        .foregroundColor(.tymerGray)
                }
            }
        }
    }
    
    private var closedWindowContent: some View {
        VStack(spacing: 32) {
            // Indicateur de fermeture
            ZStack {
                Circle()
                    .stroke(Color.tymerDarkGray, lineWidth: 2)
                    .frame(width: 160, height: 160)
                
                VStack(spacing: 8) {
                    Image(systemName: "door.left.hand.closed")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(.tymerGray)
                }
            }
            
            VStack(spacing: 12) {
                Text("Profite de ta journée")
                    .font(.tymerSubheadline)
                    .foregroundColor(.tymerWhite)
                
                Text(appState.nextWindowCountdown)
                    .font(.tymerCaption)
                    .foregroundColor(.tymerGray)
            }
            
            // Message inspirant
            Text("Le meilleur moment\nest celui que tu vis.")
                .font(.funnelLight(16))
                .foregroundColor(.tymerDarkGray)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
    
    // MARK: - Capture Section
    private var captureSection: some View {
        VStack(spacing: 16) {
            if appState.hasPostedToday {
                // Déjà posté
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Moment partagé")
                }
                .font(.funnelLight(16))
                .foregroundColor(.tymerGray)
            } else {
                // Bouton de capture
                TymerButton("Capturer mon moment", style: .secondary) {
                    appState.navigate(to: .capture)
                }
            }
        }
        .padding(.bottom, 50)
    }
    
    // MARK: - Swipe Handling
    private func handleSwipe(_ value: DragGesture.Value) {
        let horizontal = value.translation.width
        
        if horizontal < -50 {
            // Swipe left → Digest
            appState.navigate(to: .digest)
        } else if horizontal > 50 {
            // Swipe right → Circle
            appState.navigate(to: .circle)
        }
    }
}

#Preview("Window Open") {
    let appState = AppState()
    appState.isWindowOpen = true
    return GateView()
        .environment(appState)
}

#Preview("Window Closed") {
    let appState = AppState()
    appState.isWindowOpen = false
    appState.debugModeEnabled = false
    return GateView()
        .environment(appState)
}
