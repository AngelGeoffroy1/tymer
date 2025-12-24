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
        .sheet(isPresented: $showInviteSheet) {
            inviteSheet
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            TymerBackButton {
                appState.navigate(to: .gate)
            }
            
            Spacer()
            
            Text("Mon Cercle")
                .font(.tymerSubheadline)
                .foregroundColor(.tymerWhite)
            
            Spacer()
            
            // Spacer pour équilibrer
            Color.clear.frame(width: 60)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
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
                    // Copier le lien (simulé)
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
