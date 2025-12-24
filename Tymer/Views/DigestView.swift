//
//  DigestView.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI

struct DigestView: View {
    @Environment(AppState.self) private var appState
    @State private var dragOffset: CGFloat = 0
    @State private var cardsAppeared = false
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    var body: some View {
        ZStack {
            Color.tymerBlack
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Week info
                weekInfoSection
                
                // Photo grid with animation
                photoGrid
                
                Spacer()
                
                // Footer message
                footerSection
            }
        }
        .offset(x: dragOffset)
        .gesture(
            DragGesture(minimumDistance: 30)
                .onChanged { value in
                    // Swipe vers la droite uniquement (DigestView est à DROITE de Gate)
                    if value.translation.width > 0 {
                        dragOffset = value.translation.width * 0.4
                    }
                }
                .onEnded { value in
                    if value.translation.width > 80 {
                        // Swipe right → retour Gate
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            appState.navigate(to: .gate)
                        }
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                }
        )
        .onAppear {
            // Déclencher l'animation des cards
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                cardsAppeared = true
            }
        }
        .onDisappear {
            cardsAppeared = false
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            // Swipe hint vers Gate (à gauche)
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14))
                Text("Portail")
                    .font(.funnelLight(14))
            }
            .foregroundColor(.tymerGray)
            .onTapGesture {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    appState.navigate(to: .gate)
                }
            }
            
            Spacer()
            
            Text("Mon Digest")
                .font(.tymerSubheadline)
                .foregroundColor(.tymerWhite)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    // MARK: - Week Info
    private var weekInfoSection: some View {
        VStack(spacing: 8) {
            Text(weekRangeString)
                .font(.funnelLight(14))
                .foregroundColor(.tymerGray)
            
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                Text("\(appState.weeklyDigest.count) moments cette semaine")
                    .font(.funnelLight(14))
            }
            .foregroundColor(.tymerWhite)
        }
        .padding(.vertical, 24)
    }
    
    private var weekRangeString: String {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "fr_FR")
        
        return "\(formatter.string(from: weekAgo)) - \(formatter.string(from: today))"
    }
    
    // MARK: - Photo Grid
    private var photoGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(appState.weeklyDigest.enumerated()), id: \.element.id) { index, moment in
                MomentThumbnail(moment, size: thumbnailSize)
                    .scaleEffect(cardsAppeared ? 1.0 : 0.5)
                    .opacity(cardsAppeared ? 1.0 : 0)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.7)
                        .delay(Double(index) * 0.05),
                        value: cardsAppeared
                    )
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var thumbnailSize: CGFloat {
        (UIScreen.main.bounds.width - 40 - 16) / 3
    }
    
    // MARK: - Footer
    private var footerSection: some View {
        VStack(spacing: 12) {
            Text("Ton résumé personnel")
                .font(.tymerCaption)
                .foregroundColor(.tymerGray)
            
            Text("Visible uniquement par toi")
                .font(.funnelLight(12))
                .foregroundColor(.tymerDarkGray)
        }
        .padding(.bottom, 40)
    }
}

#Preview {
    DigestView()
        .environment(AppState())
}
