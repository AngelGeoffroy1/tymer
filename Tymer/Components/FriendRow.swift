//
//  FriendRow.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI

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
    
    init(_ user: User, size: CGFloat = 40) {
        self.user = user
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(user.avatarColor.opacity(0.3))
                .frame(width: size, height: size)
            
            Text(user.initials)
                .font(.funnelSemiBold(size * 0.4))
                .foregroundColor(.tymerWhite)
        }
    }
}

// MARK: - Circle Counter Badge
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
    VStack(spacing: 16) {
        FriendRow(user: User.mockUsers[0], showChevron: true)
        FriendRow(user: User.mockUsers[1])
        
        Divider().background(Color.tymerDarkGray)
        
        HStack(spacing: 8) {
            ForEach(User.mockUsers.prefix(5)) { user in
                FriendAvatar(user)
            }
        }
        
        CircleCounterBadge(current: 12, max: 25)
    }
    .padding()
    .tymerBackground()
}
