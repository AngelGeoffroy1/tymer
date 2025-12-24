//
//  MomentCard.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI

// MARK: - Moment Card Component (Full Screen)
struct MomentCard: View {
    let moment: Moment
    var onReaction: (() -> Void)? = nil
    var onMessage: (() -> Void)? = nil
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Photo placeholder (couleur en attendant vraie photo)
                Rectangle()
                    .fill(moment.placeholderColor)
                    .ignoresSafeArea()
                
                // Overlay gradient pour lisibilité
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 200)
                }
                .ignoresSafeArea()
                
                // Contenu
                VStack {
                    Spacer()
                    
                    // Info auteur
                    HStack(spacing: 12) {
                        FriendAvatar(moment.author, size: 44)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(moment.author.firstName)
                                .font(.funnelSemiBold(18))
                                .foregroundColor(.tymerWhite)
                            
                            Text(moment.relativeTimeString)
                                .font(.tymerCaption)
                                .foregroundColor(.tymerGray)
                        }
                        
                        Spacer()
                        
                        // Indicateur de réactions
                        if !moment.reactions.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.left.fill")
                                    .font(.system(size: 12))
                                Text("\(moment.reactions.count)")
                                    .font(.funnelLight(14))
                            }
                            .foregroundColor(.tymerGray)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Moment Thumbnail (Grid)
struct MomentThumbnail: View {
    let moment: Moment
    let size: CGFloat
    
    init(_ moment: Moment, size: CGFloat = 100) {
        self.moment = moment
        self.size = size
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(moment.placeholderColor)
                .frame(width: size, height: size)
            
            // Date pour le digest
            VStack {
                Spacer()
                Text(dayString)
                    .font(.funnelLight(12))
                    .foregroundColor(.tymerWhite)
                    .padding(6)
            }
        }
        .frame(width: size, height: size)
    }
    
    private var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: moment.capturedAt).capitalized
    }
}

// MARK: - Feed End Card
struct FeedEndCard: View {
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Checkmark animé
            ZStack {
                Circle()
                    .stroke(Color.tymerWhite.opacity(0.2), lineWidth: 2)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.tymerWhite)
            }
            
            VStack(spacing: 12) {
                Text("Tu as tout vu")
                    .font(.tymerHeadline)
                    .foregroundColor(.tymerWhite)
                
                Text("À demain !")
                    .font(.tymerBody)
                    .foregroundColor(.tymerGray)
            }
            
            Spacer()
            
            TymerButton("Retour au portail", style: .secondary, action: onDismiss)
                .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tymerBackground()
    }
}

#Preview("Moment Card") {
    MomentCard(moment: Moment.mockMoments()[0])
}

#Preview("Thumbnails") {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
        ForEach(Moment.mockWeeklyDigest()) { moment in
            MomentThumbnail(moment, size: 110)
        }
    }
    .padding()
    .tymerBackground()
}

#Preview("Feed End") {
    FeedEndCard(onDismiss: {})
}
