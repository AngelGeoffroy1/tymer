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
    @State private var selectedFriend: User?
    @State private var showDeleteConfirmation = false
    @State private var inviteCode: String?
    @State private var isLoadingInvite = false
    @State private var linkCopied = false

    var onNavigateToFeed: (() -> Void)?

    var body: some View {
        ZStack {
            Color.tymerBlack
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection

                    CircleOrbitRing(friends: appState.circle, maxSlots: appState.circleLimit)
                        .padding(.top, 24)
                        .padding(.bottom, 16)
                        .frame(maxWidth: .infinity)

                    friendsList

                    if appState.canAddFriend {
                        inviteSection
                    }

                    Spacer(minLength: 40)
                }
                .frame(minHeight: UIScreen.main.bounds.height - 100)
            }
        }
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

            Button {
                onNavigateToFeed?()
            } label: {
                HStack(spacing: 4) {
                    Text("Swipe")
                        .font(.funnelLight(12))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                }
                .foregroundColor(.tymerDarkGray)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    // MARK: - Friends List
    private var friendsList: some View {
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
                        if isLoadingInvite {
                            ProgressView()
                                .tint(.tymerGray)
                            Text("Génération du lien...")
                                .font(.funnelLight(14))
                                .foregroundColor(.tymerGray)
                        } else if let code = inviteCode {
                            Text("tymer.app/invite/\(code)")
                                .font(.funnelLight(14))
                                .foregroundColor(.tymerGray)
                        } else {
                            Text("Erreur de génération")
                                .font(.funnelLight(14))
                                .foregroundColor(.red.opacity(0.7))
                        }

                        Spacer()

                        Image(systemName: linkCopied ? "checkmark" : "doc.on.doc")
                            .foregroundColor(linkCopied ? .green : .tymerWhite)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.tymerDarkGray, lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                }

                Spacer()

                TymerButton(linkCopied ? "Copié !" : "Copier le lien", style: .primary) {
                    if let code = inviteCode {
                        UIPasteboard.general.string = "https://tymer.app/invite/\(code)"
                        linkCopied = true
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

                        // Reset après 2 secondes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            linkCopied = false
                            showInviteSheet = false
                        }
                    }
                }
                .disabled(inviteCode == nil || isLoadingInvite)
                .padding(.bottom, 40)
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            loadInviteCode()
        }
        .onDisappear {
            linkCopied = false
        }
    }

    private func loadInviteCode() {
        guard inviteCode == nil else { return }

        isLoadingInvite = true
        Task {
            do {
                let code = try await SupabaseManager.shared.getOrCreateInvitation()
                await MainActor.run {
                    inviteCode = code
                    isLoadingInvite = false
                }
            } catch {
                print("Error loading invite code: \(error)")
                await MainActor.run {
                    isLoadingInvite = false
                }
            }
        }
    }
}

// MARK: - Friend Row with Delete
struct FriendRowWithDelete: View {
    let user: User
    let onDelete: () -> Void

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
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Supprimer du cercle", systemImage: "person.badge.minus")
            }
        }
    }
}

#Preview {
    CircleView()
        .environment(AppState())
}
