//
//  FriendRow.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI
import UIKit

// MARK: - Friend Row Component
struct FriendRow: View {
    let user: User
    var showChevron: Bool = false
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(user.avatarColor.opacity(0.3))
                    .frame(width: 50, height: 50)
                
                Text(user.initials)
                    .font(.funnelSemiBold(20))
                    .foregroundColor(.tymerWhite)
            }
            
            // Nom
            Text(user.firstName)
                .font(.tymerBody)
                .foregroundColor(.tymerWhite)
            
            Spacer()
            
            // Chevron optionnel
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.tymerGray)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Friend Avatar (Compact)
struct FriendAvatar: View {
    let user: User
    let size: CGFloat
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    
    init(_ user: User, size: CGFloat = 40) {
        self.user = user
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Fond coloré (toujours visible)
            Circle()
                .fill(user.avatarColor.opacity(0.3))
                .frame(width: size, height: size)
            
            // Image avatar si chargée, sinon initiales
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                initialsView
            }
        }
        .onAppear {
            loadAvatarImage()
        }
    }
    
    private var initialsView: some View {
        Text(user.initials)
            .font(.funnelSemiBold(size * 0.4))
            .foregroundColor(.tymerWhite)
    }
    
    private func loadAvatarImage() {
        guard let avatarUrl = user.avatarUrl, !avatarUrl.isEmpty else { return }
        guard !isLoading else { return }
        
        // Check cache first
        if let cachedImage = ImageCache.shared.get(forKey: avatarUrl) {
            loadedImage = cachedImage
            return
        }
        
        // Load from network
        guard let url = URL(string: avatarUrl) else { return }
        
        isLoading = true
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    // Cache the image
                    ImageCache.shared.set(image, forKey: avatarUrl)
                    
                    await MainActor.run {
                        loadedImage = image
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Circle Orbit Ring
struct CircleOrbitRing: View {
    let friends: [User]
    let maxSlots: Int

    private let ringSize: CGFloat = 200
    private let avatarSize: CGFloat = 36
    private let strokeWidth: CGFloat = 3
    
    // Animation states
    @State private var rotationAngle: Double = 0
    @State private var avatarsAppeared: Bool = false

    private var progress: CGFloat {
        CGFloat(friends.count) / CGFloat(maxSlots)
    }

    private var remainingSlots: Int {
        maxSlots - friends.count
    }

    var body: some View {
        ZStack {
            // Glow effect behind the ring
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.tymerWhite.opacity(0.1),
                            Color.tymerWhite.opacity(0.05),
                            Color.clear
                        ]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90 + 360 * Double(progress))
                    ),
                    lineWidth: 20
                )
                .blur(radius: 10)
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(rotationAngle))

            // Background ring (empty slots)
            Circle()
                .stroke(
                    Color.tymerDarkGray.opacity(0.3),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, dash: [4, 8])
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(rotationAngle * 0.5)) // Slower rotation for dashed ring

            // Progress ring (filled)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [Color.tymerWhite.opacity(0.8), Color.tymerWhite.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(-90 + rotationAngle))

            // Orbiting avatars with drop animation
            ForEach(Array(friends.enumerated()), id: \.element.id) { index, friend in
                let baseAngle = angleForIndex(index, total: friends.count)
                let animatedAngle = baseAngle + CGFloat(rotationAngle * .pi / 180)

                OrbitingAvatar(
                    friend: friend,
                    angle: animatedAngle,
                    ringSize: ringSize,
                    avatarSize: avatarSize,
                    delayIndex: index,
                    hasAppeared: avatarsAppeared
                )
            }

            // Center content
            VStack(spacing: 4) {
                Text("\(friends.count)")
                    .font(.funnelSemiBold(42))
                    .foregroundColor(.tymerWhite)

                Text(friends.count == 1 ? "ami" : "amis")
                    .font(.funnelLight(14))
                    .foregroundColor(.tymerGray)
                    .textCase(.uppercase)
                    .tracking(2)

                if remainingSlots > 0 {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.tymerGray.opacity(0.5))
                            .frame(width: 4, height: 4)
                        Text("\(remainingSlots) places")
                            .font(.funnelLight(11))
                            .foregroundColor(.tymerGray.opacity(0.7))
                        Circle()
                            .fill(Color.tymerGray.opacity(0.5))
                            .frame(width: 4, height: 4)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .frame(width: ringSize + avatarSize + 20, height: ringSize + avatarSize + 20)
        .onAppear {
            // Start slow rotation animation (1 turn / 30 seconds)
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            
            // Trigger avatar drop animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                avatarsAppeared = true
            }
        }
    }

    private func angleForIndex(_ index: Int, total: Int) -> CGFloat {
        let startAngle: CGFloat = -.pi / 2 // Start from top
        let totalAngle = 2 * .pi * progress

        guard total > 1 else { return startAngle }

        let step = totalAngle / CGFloat(total)
        return startAngle + step * CGFloat(index) + step / 2
    }
}

// MARK: - Orbiting Avatar with Drop Animation
private struct OrbitingAvatar: View {
    let friend: User
    let angle: CGFloat
    let ringSize: CGFloat
    let avatarSize: CGFloat
    let delayIndex: Int
    let hasAppeared: Bool
    
    @State private var isVisible: Bool = false
    @State private var dropOffset: CGFloat = -50
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Avatar glow
            Circle()
                .fill(friend.avatarColor.opacity(0.4))
                .frame(width: avatarSize + 8, height: avatarSize + 8)
                .blur(radius: 6)

            // Avatar
            FriendAvatar(friend, size: avatarSize)
                .overlay(
                    Circle()
                        .stroke(Color.tymerBlack, lineWidth: 2)
                )
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .offset(
            x: cos(angle) * (ringSize / 2),
            y: sin(angle) * (ringSize / 2) + (isVisible ? 0 : dropOffset)
        )
        .onChange(of: hasAppeared) { _, appeared in
            if appeared {
                // Staggered drop animation
                let delay = Double(delayIndex) * 0.08
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay)) {
                    isVisible = true
                    dropOffset = 0
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
        .onAppear {
            if hasAppeared {
                // Already appeared, show immediately
                isVisible = true
                dropOffset = 0
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

// MARK: - Circle Counter Badge (Legacy)
struct CircleCounterBadge: View {
    let current: Int
    let max: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 12))
            Text("\(current)/\(max)")
                .font(.funnelLight(14))
        }
        .foregroundColor(.tymerGray)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .stroke(Color.tymerDarkGray, lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 24) {
        CircleOrbitRing(friends: Array(User.mockUsers.prefix(8)), maxSlots: 25)

        Divider().background(Color.tymerDarkGray)

        FriendRow(user: User.mockUsers[0], showChevron: true)
        FriendRow(user: User.mockUsers[1])
    }
    .padding()
    .tymerBackground()
}
