//
//  SplashView.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI

struct SplashView: View {
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    @State private var isAnimationComplete = false
    
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color.tymerBlack
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Logo / Nom
                Text("Tymer")
                    .font(.funnelSemiBold(64))
                    .foregroundColor(.tymerWhite)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                // Tagline
                Text("Reprends ton temps")
                    .font(.funnelLight(18))
                    .foregroundColor(.tymerGray)
                    .opacity(opacity)
            }
        }
        .onAppear {
            // Animation d'entrée
            withAnimation(.easeOut(duration: 0.8)) {
                opacity = 1
                scale = 1
            }
            
            // Transition après 2 secondes
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    opacity = 0
                    scale = 1.1
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
            }
        }
    }
}

#Preview {
    SplashView(onComplete: {})
}
