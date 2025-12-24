//
//  CircleView.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI

struct CircleView: View {
    @Environment(AppState.self) private var appState
    @State private var showInviteSheet = false
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.tymerBlack
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Circle counter
                CircleCounterBadge(current: appState.circleCount, max: appState.circleLimit)
                    .padding(.top, 16)
                
                // Friends list
                friendsList
                
                // Invite button
                if appState.canAddFriend {
                    inviteSection
                }
            }
        }
        .offset(x: dragOffset)
        .gesture(
            DragGesture(minimumDistance: 30)
                .onChanged { value in
                    // Swipe vers la gauche uniquement (CircleView est à GAUCHE de Gate)
                    if value.translation.width < 0 {
                        dragOffset = value.translation.width * 0.4
                    }
                }
                .onEnded { value in
                    if value.translation.width < -80 {
                        // Swipe left → retour Gate
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            appState.navigate(to: .gate)
                        }
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                }
        )
        .sheet(isPresented: $showInviteSheet) {
            inviteSheet
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            Text("Mon Cercle")
                .font(.tymerSubheadline)
                .foregroundColor(.tymerWhite)
            
            Spacer()
            
            // Swipe hint vers Gate (à droite)
            HStack(spacing: 4) {
                Text("Portail")
                    .font(.funnelLight(14))
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
            }
            .foregroundColor(.tymerGray)
            .onTapGesture {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    appState.navigate(to: .gate)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    // MARK: - Friends List
    private var friendsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(appState.circle) { friend in
                    FriendRow(user: friend)
                        .padding(.horizontal, 20)
                    
                    Divider()
                        .background(Color.tymerDarkGray)
                        .padding(.leading, 86)
                }
            }
            .padding(.top, 24)
        }
    }
    
    // MARK: - Invite Section
    private var inviteSection: some View {
        VStack(spacing: 8) {
            TymerButton("Inviter un ami", style: .secondary) {
                showInviteSheet = true
            }
            
            Text("Places restantes : \(appState.circleLimit - appState.circleCount)")
                .font(.tymerCaption)
                .foregroundColor(.tymerGray)
        }
        .padding(.vertical, 24)
    }
    
    // MARK: - Invite Sheet
    private var inviteSheet: some View {
        ZStack {
            Color.tymerBlack
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Handle
                Capsule()
                    .fill(Color.tymerDarkGray)
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)
                
                Spacer()
                
                VStack(spacing: 24) {
                    Image(systemName: "link")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(.tymerWhite)
                    
                    Text("Invite un ami")
                        .font(.tymerHeadline)
                        .foregroundColor(.tymerWhite)
                    
                    Text("Partage ce lien unique.\nSeules les personnes avec le lien peuvent rejoindre ton cercle.")
                        .font(.tymerBody)
                        .foregroundColor(.tymerGray)
                        .multilineTextAlignment(.center)
                    
                    // Fake invite link
                    HStack {
                        Text("tymer.app/invite/abc123")
                            .font(.funnelLight(14))
                            .foregroundColor(.tymerGray)
                        
                        Spacer()
                        
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.tymerWhite)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.tymerDarkGray, lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                
                TymerButton("Copier le lien", style: .primary) {
                    UIPasteboard.general.string = "tymer.app/invite/abc123"
                    showInviteSheet = false
                }
                .padding(.bottom, 40)
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    CircleView()
        .environment(AppState())
}
