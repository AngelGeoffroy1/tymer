//
//  FeedView.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI

struct FeedView: View {
    @Environment(AppState.self) private var appState
    @State private var showEndCard = false
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.tymerBlack
                .ignoresSafeArea()
            
            if showEndCard {
                // Écran de fin
                FeedEndCard {
                    appState.navigate(to: .gate)
                }
                .transition(.opacity)
            } else if !appState.moments.isEmpty {
                // Moment actuel
                momentContent
            } else {
                // Pas de moments
                emptyFeedContent
            }
        }
        .gesture(
            DragGesture(minimumDistance: 30)
                .onChanged { value in
                    dragOffset = value.translation.height
                }
                .onEnded { value in
                    handleVerticalSwipe(value)
                }
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    triggerVoiceReaction()
                }
        )
    }
    
    // MARK: - Moment Content
    private var momentContent: some View {
        ZStack {
            // Moment card
            MomentCard(moment: currentMoment)
                .offset(y: dragOffset * 0.5)
                .animation(.interactiveSpring(), value: dragOffset)
            
            // Zones de tap pour navigation
            HStack(spacing: 0) {
                // Zone gauche - photo précédente
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        goToPreviousMoment()
                    }
                
                // Zone droite - photo suivante
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        goToNextMoment()
                    }
            }
            
            // Header overlay
            VStack {
                headerOverlay
                Spacer()
            }
            
            // Progress indicator
            VStack {
                Spacer()
                progressIndicator
                    .padding(.bottom, 100)
            }
        }
    }
    
    private var currentMoment: Moment {
        appState.moments[appState.currentMomentIndex]
    }
    
    // MARK: - Header Overlay
    private var headerOverlay: some View {
        HStack {
            // Back button
            TymerBackButton {
                appState.navigate(to: .gate)
            }
            
            Spacer()
            
            // Messages button
            TymerIconButton("bubble.left.fill", size: 20) {
                appState.navigate(to: .messages)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<appState.moments.count, id: \.self) { index in
                Capsule()
                    .fill(index <= appState.currentMomentIndex ? Color.tymerWhite : Color.tymerDarkGray)
                    .frame(height: 3)
                    .animation(.easeInOut(duration: 0.2), value: appState.currentMomentIndex)
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Empty Feed
    private var emptyFeedContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.tymerGray)
            
            Text("Pas encore de moments")
                .font(.tymerBody)
                .foregroundColor(.tymerGray)
            
            TymerButton("Retour", style: .secondary) {
                appState.navigate(to: .gate)
            }
        }
    }
    
    // MARK: - Swipe Handling
    private func handleVerticalSwipe(_ value: DragGesture.Value) {
        let verticalMovement = value.translation.height
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            dragOffset = 0
        }
        
        if verticalMovement < -50 {
            // Swipe up → Next moment
            goToNextMoment()
        } else if verticalMovement > 50 {
            // Swipe down → Previous moment
            goToPreviousMoment()
        }
    }
    
    private func goToNextMoment() {
        if !appState.nextMoment() {
            // Fin du feed
            withAnimation(.easeInOut(duration: 0.3)) {
                showEndCard = true
            }
        } else {
            // Haptic feedback
            let impactGenerator = UIImpactFeedbackGenerator(style: .light)
            impactGenerator.impactOccurred()
        }
    }
    
    private func goToPreviousMoment() {
        if appState.previousMoment() {
            // Haptic feedback
            let impactGenerator = UIImpactFeedbackGenerator(style: .light)
            impactGenerator.impactOccurred()
        }
    }
    
    // MARK: - Voice Reaction
    private func triggerVoiceReaction() {
        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator.impactOccurred()
        print("🎤 Voice reaction started")
    }
}

#Preview {
    FeedView()
        .environment(AppState())
}
