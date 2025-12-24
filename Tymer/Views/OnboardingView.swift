//
//  OnboardingView.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    var onComplete: () -> Void
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "clock.arrow.circlepath",
            title: "Reprends ton temps",
            description: "Le réseau social qui te redonne du temps au lieu de t'en voler."
        ),
        OnboardingPage(
            icon: "person.2.fill",
            title: "Ton cercle intime",
            description: "15 à 25 vrais amis maximum.\nPas de followers, pas de popularité."
        ),
        OnboardingPage(
            icon: "camera.fill",
            title: "1 moment par jour",
            description: "Une seule photo par jour.\nQualité plutôt que quantité."
        ),
        OnboardingPage(
            icon: "sun.horizon.fill",
            title: "Des fenêtres",
            description: "Le feed s'ouvre 2x par jour.\nLe reste du temps : profite de ta vie."
        )
    ]
    
    var body: some View {
        ZStack {
            Color.tymerBlack
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Custom dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.tymerWhite : Color.tymerDarkGray)
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.vertical, 24)
                
                // Buttons
                VStack(spacing: 16) {
                    if currentPage == pages.count - 1 {
                        TymerButton("Commencer", style: .primary) {
                            onComplete()
                        }
                    } else {
                        TymerButton("Continuer", style: .primary) {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                    }
                    
                    if currentPage < pages.count - 1 {
                        Button("Passer") {
                            onComplete()
                        }
                        .buttonStyle(.tymerGhost)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .stroke(Color.tymerWhite.opacity(0.1), lineWidth: 2)
                    .frame(width: 140, height: 140)
                
                Image(systemName: page.icon)
                    .font(.system(size: 56, weight: .light))
                    .foregroundColor(.tymerWhite)
            }
            
            // Text
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.tymerHeadline)
                    .foregroundColor(.tymerWhite)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.tymerBody)
                    .foregroundColor(.tymerGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
