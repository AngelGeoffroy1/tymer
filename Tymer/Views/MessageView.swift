//
//  MessageView.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI

struct MessageView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        ZStack {
            Color.tymerBlack
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Messages list
                messagesList
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            TymerBackButton {
                appState.goBack()
            }
            
            Spacer()
            
            Text("Messages")
                .font(.tymerSubheadline)
                .foregroundColor(.tymerWhite)
            
            Spacer()
            
            // Spacer pour équilibrer
            Color.clear.frame(width: 60)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    // MARK: - Messages List
    private var messagesList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(allReactions) { reaction in
                    ReactionRow(reaction: reaction)
                        .padding(.horizontal, 20)
                    
                    Divider()
                        .background(Color.tymerDarkGray)
                        .padding(.leading, 86)
                }
                
                if allReactions.isEmpty {
                    emptyState
                }
            }
            .padding(.top, 24)
        }
    }
    
    private var allReactions: [ReactionWithMoment] {
        appState.moments.flatMap { moment in
            moment.reactions.map { reaction in
                ReactionWithMoment(reaction: reaction, moment: moment)
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 100)
            
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.tymerGray)
            
            VStack(spacing: 8) {
                Text("Pas encore de réactions")
                    .font(.tymerBody)
                    .foregroundColor(.tymerWhite)
                
                Text("Tes amis réagiront bientôt\nà tes moments")
                    .font(.tymerCaption)
                    .foregroundColor(.tymerGray)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Reaction Row
struct ReactionRow: View {
    let reaction: ReactionWithMoment
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            FriendAvatar(reaction.reaction.author, size: 50)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(reaction.reaction.author.firstName)
                        .font(.funnelSemiBold(16))
                        .foregroundColor(.tymerWhite)
                    
                    Text("a réagi à ton moment")
                        .font(.funnelLight(14))
                        .foregroundColor(.tymerGray)
                }
                
                // Reaction content
                reactionContent
            }
            
            Spacer()
            
            // Moment thumbnail
            RoundedRectangle(cornerRadius: 8)
                .fill(reaction.moment.placeholderColor)
                .frame(width: 44, height: 44)
        }
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    private var reactionContent: some View {
        switch reaction.reaction.type {
        case .voice(let duration):
            HStack(spacing: 6) {
                Image(systemName: "waveform")
                    .font(.system(size: 12))
                Text("\(Int(duration))s")
                    .font(.funnelLight(12))
            }
            .foregroundColor(.tymerGray)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.tymerDarkGray)
            )
            
        case .text(let message):
            Text(message)
                .font(.funnelLight(14))
                .foregroundColor(.tymerGray)
                .lineLimit(2)
        }
    }
}

// MARK: - Helper Model
struct ReactionWithMoment: Identifiable {
    let reaction: Reaction
    let moment: Moment
    
    var id: UUID { reaction.id }
}

#Preview {
    MessageView()
        .environment(AppState())
}
