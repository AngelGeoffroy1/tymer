//
//  CircleView.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct CircleView: View {
    @Environment(AppState.self) private var appState
    @State private var showInviteSheet = false
    @State private var selectedFriend: User?
    @State private var showDeleteConfirmation = false
    @State private var inviteCode: String?
    @State private var isLoadingInvite = false
    @State private var linkCopied = false
    @State private var isRefreshing = false

    var onNavigateToFeed: (() -> Void)?

    var body: some View {
        ZStack {
            Color.tymerBlack
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection

                    if appState.circle.isEmpty {
                        // Empty State
                        emptyStateView
                    } else {
                        // Normal content
                        CircleOrbitRing(friends: appState.circle, maxSlots: appState.circleLimit)
                            .padding(.top, 24)
                            .padding(.bottom, 16)
                            .frame(maxWidth: .infinity)

                        friendsList
                    }

                    if appState.canAddFriend {
                        inviteSection
                    }

                    Spacer(minLength: 40)
                }
                .frame(minHeight: UIScreen.main.bounds.height - 100)
            }
            .refreshable {
                await refreshCircle()
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
    
    // MARK: - Refresh
    private func refreshCircle() async {
        isRefreshing = true
        await appState.loadData()
        isRefreshing = false
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
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 40)
            
            // Animated illustration
            ZStack {
                // Outer ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.tymerDarkGray.opacity(0.5), Color.tymerDarkGray.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 8])
                    )
                    .frame(width: 180, height: 180)
                
                // Inner glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.tymerWhite.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)
                
                // Icon
                VStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(.tymerGray.opacity(0.6))
                    
                    Text("0")
                        .font(.funnelSemiBold(32))
                        .foregroundColor(.tymerWhite.opacity(0.3))
                }
            }
            
            VStack(spacing: 12) {
                Text("Ton cercle est vide")
                    .font(.funnelSemiBold(22))
                    .foregroundColor(.tymerWhite)
                
                Text("Invite tes proches pour partager\ndes moments ensemble.")
                    .font(.tymerBody)
                    .foregroundColor(.tymerGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // CTA Button
            TymerButton("Inviter mon premier ami", style: .primary) {
                showInviteSheet = true
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
            
            Spacer()
                .frame(height: 40)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Friends List
    private var friendsList: some View {
        LazyVStack(spacing: 0) {
            ForEach(appState.circle) { friend in
                FriendRowWithActivity(
                    user: friend,
                    lastMoment: appState.moments.first(where: { $0.author.id == friend.id })
                ) {
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

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Capsule()
                        .fill(Color.tymerDarkGray)
                        .frame(width: 40, height: 4)
                        .padding(.top, 12)

                    VStack(spacing: 16) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(.tymerWhite)

                        Text("Invite un ami")
                            .font(.tymerHeadline)
                            .foregroundColor(.tymerWhite)

                        Text("Partage le lien ou scanne le QR code\npour rejoindre ton cercle.")
                            .font(.tymerBody)
                            .foregroundColor(.tymerGray)
                            .multilineTextAlignment(.center)
                    }

                    // MARK: - QR Code Section
                    VStack(spacing: 12) {
                        Text("QR Code d'invitation")
                            .font(.funnelSemiBold(14))
                            .foregroundColor(.tymerWhite)

                        if isLoadingInvite {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.tymerDarkGray.opacity(0.3))
                                .frame(width: 180, height: 180)
                                .overlay(
                                    ProgressView()
                                        .tint(.tymerGray)
                                )
                        } else if let code = inviteCode {
                            qrCodeView(for: "https://tymer.app/invite/\(code)")
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.tymerDarkGray.opacity(0.3))
                                .frame(width: 180, height: 180)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.system(size: 24))
                                            .foregroundColor(.red.opacity(0.7))
                                        Text("Erreur")
                                            .font(.funnelLight(12))
                                            .foregroundColor(.red.opacity(0.7))
                                    }
                                )
                        }

                        Text("Scanne pour rejoindre")
                            .font(.funnelLight(12))
                            .foregroundColor(.tymerGray)
                    }
                    .padding(.vertical, 8)

                    // MARK: - Divider
                    HStack {
                        Rectangle()
                            .fill(Color.tymerDarkGray)
                            .frame(height: 1)
                        Text("ou")
                            .font(.funnelLight(12))
                            .foregroundColor(.tymerGray)
                            .padding(.horizontal, 12)
                        Rectangle()
                            .fill(Color.tymerDarkGray)
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 40)

                    // MARK: - Link Section
                    VStack(spacing: 12) {
                        Text("Lien d'invitation")
                            .font(.funnelSemiBold(14))
                            .foregroundColor(.tymerWhite)

                        HStack {
                            if isLoadingInvite {
                                ProgressView()
                                    .tint(.tymerGray)
                                Text("Génération...")
                                    .font(.funnelLight(14))
                                    .foregroundColor(.tymerGray)
                            } else if let code = inviteCode {
                                Text("tymer.app/invite/\(code)")
                                    .font(.funnelLight(14))
                                    .foregroundColor(.tymerGray)
                                    .lineLimit(1)
                            } else {
                                Text("Erreur de génération")
                                    .font(.funnelLight(14))
                                    .foregroundColor(.red.opacity(0.7))
                            }

                            Spacer()

                            Image(systemName: linkCopied ? "checkmark" : "doc.on.doc")
                                .foregroundColor(linkCopied ? .green : .tymerWhite)
                                .font(.system(size: 14))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.tymerDarkGray, lineWidth: 1)
                        )
                        .padding(.horizontal, 24)
                    }

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
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.large])
        .onAppear {
            loadInviteCode()
        }
        .onDisappear {
            linkCopied = false
        }
    }
    
    // MARK: - QR Code Generator
    private func qrCodeView(for string: String) -> some View {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        
        if let outputImage = filter.outputImage {
            // Scale up the QR code
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                let uiImage = UIImage(cgImage: cgImage)
                
                return AnyView(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .frame(width: 190, height: 190)
                        
                        Image(uiImage: uiImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 160, height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .shadow(color: .tymerWhite.opacity(0.1), radius: 20, x: 0, y: 0)
                )
            }
        }
        
        return AnyView(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.tymerDarkGray.opacity(0.3))
                .frame(width: 180, height: 180)
                .overlay(
                    Text("Erreur QR")
                        .font(.funnelLight(12))
                        .foregroundColor(.red.opacity(0.7))
                )
        )
    }

    private func loadInviteCode() {
        guard inviteCode == nil else { return }

        isLoadingInvite = true
        Task {
            // Retry logic for newly created accounts
            var lastError: Error?
            for attempt in 1...3 {
                do {
                    let code = try await SupabaseManager.shared.getOrCreateInvitation()
                    await MainActor.run {
                        inviteCode = code
                        isLoadingInvite = false
                    }
                    return
                } catch {
                    lastError = error
                    print("⚠️ Attempt \(attempt)/3 failed to load invite code: \(error)")

                    if attempt < 3 {
                        // Wait before retrying: 300ms, 600ms
                        try? await Task.sleep(nanoseconds: UInt64(300_000_000 * attempt))
                    }
                }
            }

            // All attempts failed
            print("❌ Failed to load invite code after 3 attempts: \(lastError?.localizedDescription ?? "Unknown error")")
            await MainActor.run {
                isLoadingInvite = false
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

// MARK: - Friend Row with Activity (Last Post)
struct FriendRowWithActivity: View {
    let user: User
    let lastMoment: Moment?
    let onDelete: () -> Void
    
    /// Check if the friend posted recently (within last 24 hours)
    private var hasRecentActivity: Bool {
        guard let moment = lastMoment else { return false }
        let hoursAgo = Date().timeIntervalSince(moment.capturedAt) / 3600
        return hoursAgo < 24
    }
    
    /// Format the last post time
    private var lastActivityText: String {
        guard let moment = lastMoment else {
            return "Aucun post"
        }
        
        let calendar = Calendar.current
        let now = Date()
        let postDate = moment.capturedAt
        
        // If posted today
        if calendar.isDateInToday(postDate) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "Posté à \(formatter.string(from: postDate))"
        }
        
        // If posted yesterday
        if calendar.isDateInYesterday(postDate) {
            return "Posté hier"
        }
        
        // Relative time for older posts
        let daysDiff = calendar.dateComponents([.day], from: postDate, to: now).day ?? 0
        if daysDiff < 7 {
            return "Posté il y a \(daysDiff)j"
        }
        
        return "Posté il y a +1 sem."
    }

    var body: some View {
        HStack(spacing: 16) {
            // Avatar with activity indicator
            ZStack(alignment: .topLeading) {
                FriendAvatar(user, size: 50)
                
                // Green dot for recent activity
                if hasRecentActivity {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.tymerBlack, lineWidth: 2)
                        )
                        .offset(x: -2, y: -2)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(user.firstName)
                    .font(.funnelSemiBold(16))
                    .foregroundColor(.tymerWhite)

                HStack(spacing: 4) {
                    if hasRecentActivity {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                    }
                    
                    Text(lastActivityText)
                        .font(.funnelLight(12))
                        .foregroundColor(hasRecentActivity ? .tymerWhite.opacity(0.7) : .tymerGray)
                }
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
