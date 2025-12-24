//
//  CaptureView.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI

struct CaptureView: View {
    @Environment(AppState.self) private var appState
    @State private var showPreview = false
    @State private var capturedColor: Color = .tymerDarkGray
    @State private var flashAnimation = false
    
    // Couleurs aléatoires pour simuler des photos
    private let placeholderColors: [Color] = [
        .red, .blue, .green, .orange, .purple, .pink, .cyan, .yellow, .mint, .indigo
    ]
    
    var body: some View {
        ZStack {
            Color.tymerBlack
                .ignoresSafeArea()
            
            if appState.hasPostedToday {
                // Déjà posté
                alreadyPostedContent
            } else if showPreview {
                // Preview après capture
                previewContent
            } else {
                // Interface caméra
                cameraContent
            }
            
            // Flash effect
            if flashAnimation {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
    }
    
    // MARK: - Camera Content
    private var cameraContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                TymerBackButton {
                    appState.navigate(to: .gate)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            Spacer()
            
            // Camera preview placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.tymerDarkGray.opacity(0.3))
                    .frame(height: UIScreen.main.bounds.height * 0.55)
                    .padding(.horizontal, 20)
                
                VStack(spacing: 16) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 64, weight: .ultraLight))
                        .foregroundColor(.tymerGray)
                    
                    Text("Cadre ton moment")
                        .font(.tymerBody)
                        .foregroundColor(.tymerGray)
                }
            }
            
            Spacer()
            
            // Capture button
            captureButton
                .padding(.bottom, 60)
        }
    }
    
    private var captureButton: some View {
        Button(action: capturePhoto) {
            ZStack {
                Circle()
                    .stroke(Color.tymerWhite, lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .fill(Color.tymerWhite)
                    .frame(width: 64, height: 64)
            }
        }
    }
    
    // MARK: - Preview Content
    private var previewContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Reprendre") {
                    withAnimation {
                        showPreview = false
                    }
                }
                .font(.funnelLight(16))
                .foregroundColor(.tymerWhite)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            Spacer()
            
            // Preview
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(capturedColor.opacity(0.4))
                    .frame(height: UIScreen.main.bounds.height * 0.55)
                    .padding(.horizontal, 20)
                
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.tymerWhite)
                    
                    Text("Ton moment")
                        .font(.tymerSubheadline)
                        .foregroundColor(.tymerWhite)
                }
            }
            
            Spacer()
            
            // Confirm button
            VStack(spacing: 16) {
                TymerButton("Partager mon moment", style: .primary) {
                    sharePhoto()
                }
                
                Button("Annuler") {
                    withAnimation {
                        showPreview = false
                    }
                }
                .buttonStyle(.tymerGhost)
            }
            .padding(.bottom, 60)
        }
    }
    
    // MARK: - Already Posted Content
    private var alreadyPostedContent: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.tymerWhite.opacity(0.2), lineWidth: 2)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.tymerWhite)
            }
            
            VStack(spacing: 12) {
                Text("Moment partagé")
                    .font(.tymerHeadline)
                    .foregroundColor(.tymerWhite)
                
                Text("Tu as déjà capturé ton moment aujourd'hui.\nÀ demain !")
                    .font(.tymerBody)
                    .foregroundColor(.tymerGray)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            TymerButton("Retour au portail", style: .secondary) {
                appState.navigate(to: .gate)
            }
            .padding(.bottom, 60)
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Actions
    private func capturePhoto() {
        // Flash effect
        withAnimation(.easeIn(duration: 0.1)) {
            flashAnimation = true
        }
        
        // Haptic
        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator.impactOccurred()
        
        // Simulate capture
        capturedColor = placeholderColors.randomElement() ?? .tymerDarkGray
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.2)) {
                flashAnimation = false
            }
            withAnimation {
                showPreview = true
            }
        }
    }
    
    private func sharePhoto() {
        // Poster le moment
        appState.postMoment(placeholderColor: capturedColor)
        
        // Retour au portail
        appState.navigate(to: .gate)
    }
}

#Preview {
    CaptureView()
        .environment(AppState())
}

#Preview("Already Posted") {
    let state = AppState()
    state.hasPostedToday = true
    return CaptureView()
        .environment(state)
}
