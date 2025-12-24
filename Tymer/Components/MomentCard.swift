//
//  MomentCard.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI

// MARK: - Mock Photo Patterns
struct MockPhotoPattern: View {
    let baseColor: Color
    let patternType: Int
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [baseColor.opacity(0.6), baseColor.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Pattern overlay based on type
            switch patternType % 4 {
            case 0:
                // Circles pattern
                circlesPattern
            case 1:
                // Waves pattern
                wavesPattern
            case 2:
                // Diagonal lines
                diagonalPattern
            default:
                // Dots pattern
                dotsPattern
            }
        }
    }
    
    private var circlesPattern: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(baseColor.opacity(0.2))
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: geo.size.width * 0.3, y: -geo.size.height * 0.2)
                
                Circle()
                    .fill(baseColor.opacity(0.15))
                    .frame(width: geo.size.width * 0.4)
                    .offset(x: -geo.size.width * 0.2, y: geo.size.height * 0.3)
                
                Circle()
                    .stroke(baseColor.opacity(0.3), lineWidth: 2)
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: geo.size.width * 0.1, y: geo.size.height * 0.1)
            }
        }
    }
    
    private var wavesPattern: some View {
        GeometryReader { geo in
            Path { path in
                let width = geo.size.width
                let height = geo.size.height
                let waveHeight: CGFloat = 30
                
                for i in 0..<5 {
                    let y = height * CGFloat(i + 1) / 6
                    path.move(to: CGPoint(x: 0, y: y))
                    
                    for x in stride(from: 0, to: width, by: 20) {
                        let relativeX = x / width
                        let offsetY = sin(relativeX * .pi * 2) * waveHeight
                        path.addLine(to: CGPoint(x: x, y: y + offsetY))
                    }
                }
            }
            .stroke(baseColor.opacity(0.2), lineWidth: 2)
        }
    }
    
    private var diagonalPattern: some View {
        GeometryReader { geo in
            Path { path in
                let spacing: CGFloat = 40
                let count = Int((geo.size.width + geo.size.height) / spacing)
                
                for i in 0..<count {
                    let offset = CGFloat(i) * spacing
                    path.move(to: CGPoint(x: offset, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: offset))
                }
            }
            .stroke(baseColor.opacity(0.15), lineWidth: 1)
        }
    }
    
    private var dotsPattern: some View {
        GeometryReader { geo in
            let cols = 8
            let rows = 12
            let dotSize: CGFloat = 8
            
            ForEach(0..<rows, id: \.self) { row in
                ForEach(0..<cols, id: \.self) { col in
                    Circle()
                        .fill(baseColor.opacity(0.2))
                        .frame(width: dotSize, height: dotSize)
                        .position(
                            x: geo.size.width * CGFloat(col + 1) / CGFloat(cols + 1),
                            y: geo.size.height * CGFloat(row + 1) / CGFloat(rows + 1)
                        )
                }
            }
        }
    }
}

// MARK: - Moment Card Component (Full Screen)
struct MomentCard: View {
    let moment: Moment
    var onReaction: (() -> Void)? = nil
    var onMessage: (() -> Void)? = nil
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Photo mock avec pattern
                MockPhotoPattern(
                    baseColor: moment.placeholderColor,
                    patternType: abs(moment.id.hashValue) % 4
                )
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
            // Pattern background
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [moment.placeholderColor.opacity(0.6), moment.placeholderColor.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            
            // Date pour le digest
            VStack {
                Spacer()
                Text(dayString)
                    .font(.funnelSemiBold(12))
                    .foregroundColor(.tymerWhite)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Capsule())
                    .padding(8)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
    @State private var checkmarkScale: CGFloat = 0.5
    @State private var checkmarkOpacity: Double = 0
    
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
                    .scaleEffect(checkmarkScale)
                    .opacity(checkmarkOpacity)
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
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                checkmarkScale = 1.0
                checkmarkOpacity = 1.0
            }
        }
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
