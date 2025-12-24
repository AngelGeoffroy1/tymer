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
    @State private var selectedFriend: User?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ZStack {
            Color.tymerBlack
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                
                CircleCounterBadge(current: appState.circleCount, max: appState.circleLimit)
                    .padding(.top, 16)
                
                friendsList
                
                if appState.canAddFriend {
                    inviteSection
                }
            }
        }
        .offset(x: dragOffset)
        .gesture(
            DragGesture(minimumDistance: 30)
                .onChanged { value in
                    if value.translation.width < 0 {
                        dragOffset = value.translation.width * 0.4
                    }
                }
                .onEnded { value in
                    if value.translation.width < -80 {
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
        .confirmationDialog(
            "Supprimer \(selectedFriend?.firstName ?? "") de ton cercle ?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Supprimer", role: .destructive) {
                if let friend = selectedFriend {
                    withAnimation {
                        appState.removeFriend(friend)
                    }
                }
                selectedFriend = nil
            }
            Button("Annuler", role: .cancel) {
                selectedFriend = nil
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            Text("Mon Cercle")
                .font(.tymerSubheadline)
                .foregroundColor(.tymerWhite)
            
            Spacer()
            
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
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(appState.circle) { friend in
                    FriendRowWithDelete(user: friend) {
                        selectedFriend = friend
                        showDeleteConfirmation = true
                    }
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

// MARK: - Friend Row with Delete
struct FriendRowWithDelete: View {
    let user: User
    let onDelete: () -> Void
    
    @State private var showDeleteButton = false
    
    var body: some View {
        HStack(spacing: 16) {
            FriendAvatar(user, size: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.firstName)
                    .font(.funnelSemiBold(16))
                    .foregroundColor(.tymerWhite)
                
                Text("Dans le cercle")
                    .font(.funnelLight(12))
                    .foregroundColor(.tymerGray)
            }
            
            Spacer()
            
            if showDeleteButton {
                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.2))
                        .clipShape(Circle())
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showDeleteButton.toggle()
            }
            
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
        .onTapGesture {
            if showDeleteButton {
                withAnimation {
                    showDeleteButton = false
                }
            }
        }
    }
}

#Preview {
    CircleView()
        .environment(AppState())
}
