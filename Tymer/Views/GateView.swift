//
//  GateView.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI

// MARK: - Scroll Offset Detector (iOS 17 compatible)
private struct ScrollOffsetModifier: ViewModifier {
    let onScroll: (_ offset: CGFloat, _ delta: CGFloat) -> Void
    @State private var lastOffset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onChange(of: geo.frame(in: .global).minY) { oldValue, newValue in
                            let delta = newValue - oldValue
                            onScroll(newValue, delta)
                        }
                }
            )
    }
}

struct GateView: View {
    @Environment(AppState.self) private var appState
    @StateObject private var supabase = SupabaseManager.shared

    @State private var headerVisible: Bool = true
    @State private var scrollStartY: CGFloat = 0
    @State private var hasScrolledEnough: Bool = false
    @State private var selectedTab: Int = 1 // 0 = Circle, 1 = Feed, 2 = Profile
    @State private var isRefreshing: Bool = false

    var body: some View {
        ZStack {
            Color.tymerBlack
                .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                // Page 0: CircleView
                CircleView(onNavigateToFeed: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = 1
                    }
                })
                .tag(0)

                // Page 1: Feed (contenu principal)
                feedPage
                    .tag(1)

                // Page 2: ProfileView
                ProfileView(onNavigateToFeed: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = 1
                    }
                })
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
        }
    }

    // MARK: - Feed Page (ancienne vue principale)
    private var feedPage: some View {
        ZStack(alignment: .top) {
            // Contenu scrollable - occupe tout l'écran
            feedSection

            // Header en overlay - glisse vers le haut pour disparaître
            VStack(spacing: 0) {
                headerSection
                windowStatusBar
            }
            .background(Color.tymerBlack)
            .offset(y: headerVisible ? 0 : -100)
            .opacity(headerVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.25), value: headerVisible)
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    selectedTab = 0
                }
            }) {
                VStack(spacing: 2) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 16))
                    Text("\(appState.circleCount)")
                        .font(.funnelLight(10))
                }
                .foregroundColor(.tymerGray)
            }

            Spacer()

            Text("Tymer")
                .font(.funnelSemiBold(24))
                .foregroundColor(.tymerWhite)

            Spacer()

            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    selectedTab = 2
                }
            }) {
                VStack(spacing: 2) {
                    // Afficher l'avatar image si disponible, sinon l'icône
                    if let profile = supabase.currentProfile {
                        let user = profile.toUser()
                        if user.avatarUrl != nil {
                            FriendAvatar(user, size: 24)
                        } else {
                            // Fallback: initiales colorées
                            Circle()
                                .fill(profile.displayColor.opacity(0.3))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Text(profile.initials)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.tymerWhite)
                                )
                        }
                    } else {
                        Image(systemName: "person.circle")
                            .font(.system(size: 16))
                    }
                    Text("Profil")
                        .font(.funnelLight(10))
                }
                .foregroundColor(.tymerGray)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .contentShape(Rectangle()) // Pour capter les touches
    }
    
    // MARK: - Window Status Bar
    private var windowStatusBar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(appState.isWindowOpen ? Color.green : Color.tymerDarkGray)
                .frame(width: 6, height: 6)

            if appState.isWindowOpen {
                Text("Fenêtre ouverte")
                    .font(.funnelSemiBold(11))
                    .foregroundColor(.tymerWhite)
            } else {
                Text("Fermée")
                    .font(.funnelSemiBold(11))
                    .foregroundColor(.tymerGray)
            }

            Text("•")
                .foregroundColor(.tymerDarkGray)

            Text(appState.nextWindowCountdown)
                .font(.funnelLight(11))
                .foregroundColor(.tymerDarkGray)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
    
    // MARK: - Feed Section
    private var feedSection: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Espace pour le header (à l'intérieur du scroll)
                Color.clear
                    .frame(height: 90)

                // Tracker pour détecter le scroll
                Color.clear
                    .frame(height: 1)
                    .modifier(ScrollOffsetModifier { offset, delta in
                        handleScrollDelta(offset: offset, delta: delta)
                    })

                myCaptureCard

                if !appState.moments.isEmpty {
                    HStack {
                        Rectangle()
                            .fill(Color.tymerDarkGray)
                            .frame(height: 1)
                        Text("Cercle")
                            .font(.funnelLight(11))
                            .foregroundColor(.tymerGray)
                            .padding(.horizontal, 8)
                        Rectangle()
                            .fill(Color.tymerDarkGray)
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 16)

                    ForEach(appState.moments) { moment in
                        PostCard(
                            moment: moment,
                            isBlurred: !appState.isWindowOpen
                        )
                    }
                } else {
                    // Empty state - no moments from friends
                    emptyFeedState
                }
            }
            .padding(.bottom, 100)
        }
        .refreshable {
            await refreshFeed()
        }
    }

    // MARK: - Refresh
    private func refreshFeed() async {
        isRefreshing = true
        await appState.loadData()
        isRefreshing = false
    }

    // MARK: - Scroll Handling
    private func handleScrollDelta(offset: CGFloat, delta: CGFloat) {
        // Ignorer les micro-mouvements
        guard abs(delta) > 3 else { return }

        // Scroll vers le bas (delta négatif car offset diminue) -> cacher
        if delta < -8 && headerVisible && hasScrolledEnough {
            withAnimation(.easeInOut(duration: 0.2)) {
                headerVisible = false
            }
        }
        // Scroll vers le haut (delta positif) -> montrer
        else if delta > 8 && !headerVisible {
            withAnimation(.easeInOut(duration: 0.2)) {
                headerVisible = true
            }
        }

        // Tracker si on a assez scrollé pour pouvoir cacher le header
        if scrollStartY == 0 {
            scrollStartY = offset
        }
        hasScrolledEnough = abs(offset - scrollStartY) > 100

        // Reset quand on revient en haut
        if offset > scrollStartY - 20 {
            scrollStartY = offset
            hasScrolledEnough = false
            if !headerVisible {
                withAnimation(.easeInOut(duration: 0.2)) {
                    headerVisible = true
                }
            }
        }
    }
    
    // MARK: - My Capture Card
    private var myCaptureCard: some View {
        Group {
            if appState.isUploadingMoment {
                uploadingCard
            } else if appState.hasPostedToday, let myMoment = appState.myTodayMoment {
                PostCard(moment: myMoment, isBlurred: false, isMyPost: true)
            } else {
                capturePromptCard
            }
        }
    }

    private var uploadingCard: some View {
        HStack(spacing: 16) {
            ProgressView()
                .tint(.tymerWhite)
                .scaleEffect(1.2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Publication en cours...")
                    .font(.funnelSemiBold(14))
                    .foregroundColor(.tymerWhite)
                Text("Ton moment arrive")
                    .font(.funnelLight(12))
                    .foregroundColor(.tymerGray)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.tymerDarkGray.opacity(0.3))
        )
        .padding(.horizontal, 16)
    }
    
    private var capturePromptCard: some View {
        Button(action: {
            appState.navigate(to: .capture)
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.tymerWhite.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 50, height: 50)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.tymerWhite)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Capturer mon moment")
                        .font(.funnelSemiBold(14))
                        .foregroundColor(.tymerWhite)
                    Text("Une seule photo par jour")
                        .font(.funnelLight(12))
                        .foregroundColor(.tymerGray)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.tymerDarkGray)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.tymerDarkGray.opacity(0.3))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
    }

    // MARK: - Empty Feed State
    private var emptyFeedState: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 40)

            // Illustration
            ZStack {
                Circle()
                    .stroke(Color.tymerDarkGray.opacity(0.3), lineWidth: 2)
                    .frame(width: 120, height: 120)

                Circle()
                    .stroke(Color.tymerDarkGray.opacity(0.2), lineWidth: 1)
                    .frame(width: 160, height: 160)

                Image(systemName: "person.2.slash")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.tymerGray)
            }

            VStack(spacing: 12) {
                Text("Ton cercle est silencieux")
                    .font(.funnelSemiBold(18))
                    .foregroundColor(.tymerWhite)

                Text(emptyStateMessage)
                    .font(.funnelLight(14))
                    .foregroundColor(.tymerGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Actions
            VStack(spacing: 12) {
                if !appState.hasPostedToday {
                    Button {
                        appState.navigate(to: .capture)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                            Text("Capturer mon moment")
                                .font(.funnelSemiBold(14))
                        }
                        .foregroundColor(.tymerBlack)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Color.tymerWhite)
                        .clipShape(Capsule())
                    }
                }

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = 0
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 14))
                        Text("Inviter des amis")
                            .font(.funnelLight(14))
                    }
                    .foregroundColor(.tymerWhite)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .stroke(Color.tymerDarkGray, lineWidth: 1)
                    )
                }
            }

            Spacer()
                .frame(height: 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }

    private var emptyStateMessage: String {
        if appState.circle.isEmpty {
            return "Invite tes amis pour voir leurs moments quotidiens"
        } else if !appState.hasPostedToday {
            return "Sois le premier à partager ton moment aujourd'hui !"
        } else {
            return "Tes amis n'ont pas encore posté aujourd'hui"
        }
    }
}

// MARK: - Post Card Component
struct PostCard: View {
    let moment: Moment
    let isBlurred: Bool
    var isMyPost: Bool = false
    
    @Environment(AppState.self) private var appState
    @State private var showReactionSheet = false
    @State private var reactionText = ""
    @State private var isRecordingVoice = false
    @State private var recordingTimer: Timer?
    @State private var showExpandedReactions = false
    @State private var recordingDuration: Double = 0
    @State private var showMomentMenu = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false

    private var windowDisplayText: String {
        let windows = appState.timeWindows.isEmpty ? TimeWindow.defaultWindows : appState.timeWindows
        return windows.map { $0.displayTime }.joined(separator: " • ")
    }

    private var placeholderPattern: some View {
        MockPhotoPattern(
            baseColor: moment.placeholderColor,
            patternType: abs(moment.id.hashValue) % 4
        )
        .frame(height: 400)
        .blur(radius: isBlurred ? 30 : 0)
        .allowsHitTesting(false)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            postHeader
            photoSection

            // Description du moment
            if let description = moment.description, !description.isEmpty, !isBlurred {
                Text(description)
                    .font(.funnelLight(14))
                    .foregroundColor(.tymerWhite)
                    .padding(.horizontal, 4)
                    .padding(.top, 12)
            }

            // Actions (pour tous les posts, y compris le mien)
            if !isBlurred {
                actionsSection
            }

            if !moment.reactions.isEmpty && !isBlurred {
                reactionsPreview
            }
        }
        .background(Color.tymerBlack)
        .padding(.horizontal, 16)
        .sheet(isPresented: $showReactionSheet) {
            reactionSheet
        }
        .confirmationDialog("Options du moment", isPresented: $showMomentMenu, titleVisibility: .hidden) {
            Button("Reprendre le moment") {
                // Set retake mode and navigate to capture
                appState.isRetakingMoment = true
                appState.momentToReplace = moment
                appState.currentScreen = .capture
            }
            Button("Supprimer", role: .destructive) {
                showDeleteConfirmation = true
            }
            Button("Annuler", role: .cancel) {}
        }
        .confirmationDialog("Supprimer ce moment ?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Supprimer", role: .destructive) {
                Task {
                    isDeleting = true
                    do {
                        try await appState.deleteMyTodayMoment()
                    } catch {
                        print("Error deleting moment: \(error)")
                    }
                    isDeleting = false
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Cette action est irréversible.")
        }
    }
    
    private var postHeader: some View {
        HStack(spacing: 10) {
            FriendAvatar(moment.author, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(isMyPost ? "Mon moment" : moment.author.firstName)
                    .font(.funnelSemiBold(14))
                    .foregroundColor(.tymerWhite)
                Text(moment.relativeTimeString)
                    .font(.funnelLight(12))
                    .foregroundColor(.tymerGray)
            }
            Spacer()

            // Menu button for my posts
            if isMyPost {
                Button {
                    showMomentMenu = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.tymerGray)
                        .frame(width: 32, height: 32)
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 12)
    }
    
    private var photoSection: some View {
        ZStack {
            if let imagePath = moment.imageName {
                // Check if it's a Supabase path or local
                if PhotoLoader.isSupabasePath(imagePath) {
                    SupabaseImage(path: imagePath, height: 400, blurRadius: isBlurred ? 30 : 0)
                        .allowsHitTesting(false)
                } else if let uiImage = PhotoLoader.loadImage(named: imagePath) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 400)
                        .clipped()
                        .blur(radius: isBlurred ? 30 : 0)
                        .allowsHitTesting(false)
                } else {
                    placeholderPattern
                }
            } else {
                placeholderPattern
            }

            if isBlurred {
                VStack(spacing: 12) {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.tymerWhite)
                    Text("Visible pendant la fenêtre")
                        .font(.funnelSemiBold(13))
                        .foregroundColor(.tymerWhite)
                    Text(windowDisplayText)
                        .font(.funnelLight(11))
                        .foregroundColor(.tymerGray)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.5))
                )
                .allowsHitTesting(false)
            }
        }
        .frame(height: 400)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16)) // Zone de hit limitée au rectangle visible
    }
    
    private var actionsSection: some View {
        HStack(spacing: 12) {
            // Bouton vocal - tap pour start/stop
            Button {
                print("🎤 Bouton Vocal tappé!")
                if isRecordingVoice {
                    stopRecording()
                } else {
                    startRecording()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isRecordingVoice ? "stop.fill" : "mic.fill")
                        .font(.system(size: 14))
                    if isRecordingVoice {
                        Text(String(format: "%.1fs", recordingDuration))
                            .font(.funnelLight(12))
                    } else {
                        Text("Vocal")
                            .font(.funnelLight(12))
                    }
                }
                .foregroundColor(isRecordingVoice ? .red : .tymerWhite)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isRecordingVoice ? Color.red.opacity(0.3) : Color.tymerDarkGray)
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Bouton texte
            Button {
                print("💬 Bouton Message tappé!")
                showReactionSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 14))
                    Text("Message")
                        .font(.funnelLight(12))
                }
                .foregroundColor(.tymerGray)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .stroke(Color.tymerDarkGray, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
    }
    
    private var reactionsPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header cliquable pour expand/collapse
            Button {
                print("📋 Bouton Réactions tappé!")
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showExpandedReactions.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    if !showExpandedReactions {
                        HStack(spacing: -8) {
                            ForEach(moment.reactions.prefix(3)) { reaction in
                                FriendAvatar(reaction.author, size: 22)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.tymerBlack, lineWidth: 2)
                                    )
                            }
                        }
                    }

                    Text(showExpandedReactions ? "Moins" : "\(moment.reactions.count) réaction\(moment.reactions.count > 1 ? "s" : "")")
                        .font(.funnelLight(11))
                        .foregroundColor(.tymerGray)

                    Image(systemName: showExpandedReactions ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.tymerGray)

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Liste déroulée des réactions
            if showExpandedReactions {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(moment.reactions) { reaction in
                        ReactionRow(reaction: reaction)
                    }
                }
                .padding(.top, 4)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
    }
    
    private var reactionSheet: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.tymerDarkGray)
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            Text(isMyPost ? "Ajouter un commentaire" : "Message à \(moment.author.firstName)")
                .font(.funnelSemiBold(16))
                .foregroundColor(.tymerWhite)
            
            HStack(spacing: 12) {
                TextField("", text: $reactionText, prompt: Text("Ton message...").foregroundColor(.tymerGray))
                    .font(.funnelLight(14))
                    .foregroundColor(.tymerWhite)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.tymerDarkGray.opacity(0.5))
                    )
                    .onSubmit {
                        sendTextReaction()
                    }
                
                Button {
                    sendTextReaction()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(reactionText.isEmpty ? .tymerDarkGray : .tymerWhite)
                }
                .disabled(reactionText.isEmpty)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.tymerBlack)
        .presentationDetents([.height(200)])
        .presentationDragIndicator(.hidden)
    }
    
    // MARK: - Recording
    private func startRecording() {
        isRecordingVoice = true
        recordingDuration = 0
        
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        appState.startVoiceRecording()
        
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingDuration += 0.1
            if recordingDuration >= 3 {
                stopRecording()
            }
        }
    }
    
    private func stopRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil

        guard isRecordingVoice else { return }
        isRecordingVoice = false

        let result = appState.stopVoiceRecording()

        if recordingDuration > 0.3 {
            appState.addVoiceReaction(
                to: moment,
                duration: max(result.duration, recordingDuration),
                audioData: result.audioData,
                waveformData: result.waveform
            )
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        recordingDuration = 0
    }
    
    private func sendTextReaction() {
        guard !reactionText.isEmpty else { return }
        appState.addTextReaction(to: moment, text: reactionText)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        reactionText = ""
        showReactionSheet = false
    }
}

// MARK: - Reaction Row Component
struct ReactionRow: View {
    let reaction: Reaction
    @Environment(AppState.self) private var appState

    private var isPlaying: Bool {
        appState.currentlyPlayingReactionId == reaction.id
    }

    private var isLoading: Bool {
        appState.isLoadingAudio && appState.currentlyPlayingReactionId == reaction.id
    }

    private var progress: Double {
        isPlaying ? appState.audioPlaybackProgress : 0
    }

    private var isVoice: Bool {
        if case .voice = reaction.type { return true }
        return false
    }

    var body: some View {
        HStack(spacing: 10) {
            FriendAvatar(reaction.author, size: 28)

            VStack(alignment: .leading, spacing: 2) {
                // Masquer le nom pour les réactions vocales
                if !isVoice {
                    Text(reaction.author.firstName)
                        .font(.funnelSemiBold(12))
                        .foregroundColor(.tymerWhite)
                }

                reactionContent
            }

            Spacer()

            Text(relativeTime)
                .font(.funnelLight(10))
                .foregroundColor(.tymerDarkGray)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var reactionContent: some View {
        switch reaction.type {
        case .voice(let duration):
            Button {
                appState.playVoiceReaction(reaction)
            } label: {
                voiceReactionView(duration: duration)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(reaction.voicePath == nil)
            .opacity(reaction.voicePath == nil ? 0.5 : 1)

        case .text(let message):
            Text(message)
                .font(.funnelLight(12))
                .foregroundColor(.tymerGray)
        }
    }

    // Génère des hauteurs de barres - utilise les vraies données si disponibles
    private func waveformHeights(count: Int) -> [CGFloat] {
        // Si on a des vraies données de waveform, les utiliser
        if let waveform = reaction.waveformData, !waveform.isEmpty {
            // Resampler si nécessaire
            if waveform.count == count {
                return waveform.map { CGFloat($0) }
            } else {
                return resampleWaveform(waveform, to: count).map { CGFloat($0) }
            }
        }

        // Fallback: génération pseudo-aléatoire basée sur l'ID
        let seed = reaction.id.hashValue
        return (0..<count).map { i in
            let value = abs(sin(Double(seed + i * 7) * 0.3))
            return CGFloat(0.3 + value * 0.7)
        }
    }

    private func resampleWaveform(_ samples: [Float], to targetCount: Int) -> [Float] {
        guard !samples.isEmpty else { return Array(repeating: 0.3, count: targetCount) }
        guard samples.count > targetCount else { return samples }

        let chunkSize = samples.count / targetCount
        var result: [Float] = []

        for i in 0..<targetCount {
            let start = i * chunkSize
            let end = min(start + chunkSize, samples.count)
            let chunk = samples[start..<end]
            let maxValue = chunk.max() ?? 0.3
            result.append(max(0.15, maxValue))
        }

        return result
    }

    @ViewBuilder
    private func voiceReactionView(duration: TimeInterval) -> some View {
        // Largeur proportionnelle à la durée (min 100, max 180 pour 3s)
        let baseWidth: CGFloat = 100
        let maxExtraWidth: CGFloat = 80
        let durationRatio = min(duration / 3.0, 1.0)
        let totalWidth = baseWidth + (maxExtraWidth * durationRatio)

        // Nombre de barres proportionnel à la largeur
        let barCount = Int(12 + (12 * durationRatio))
        let heights = waveformHeights(count: barCount)

        HStack(spacing: 5) {
            // Bouton play/pause
            if isLoading {
                ProgressView()
                    .scaleEffect(0.6)
                    .tint(.tymerWhite)
                    .frame(width: 18, height: 18)
            } else {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.tymerWhite)
                    .frame(width: 18, height: 18)
            }

            // Waveform style Instagram
            HStack(spacing: 2) {
                ForEach(0..<barCount, id: \.self) { index in
                    let barProgress = Double(index) / Double(barCount)
                    let isPlayed = progress > barProgress

                    RoundedRectangle(cornerRadius: 1)
                        .fill(isPlayed ? Color.tymerWhite : Color.tymerWhite.opacity(0.4))
                        .frame(width: 2, height: 16 * heights[index])
                }
            }
            .frame(height: 20)

            // Durée
            Text("\(String(format: "%.0f", duration))s")
                .font(.funnelLight(10))
                .foregroundColor(.tymerWhite.opacity(0.8))
                .frame(width: 18, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(width: totalWidth)
        .background(
            Capsule()
                .fill(isPlaying ? Color.tymerDarkGray : Color.tymerDarkGray.opacity(0.6))
        )
    }

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.localizedString(for: reaction.createdAt, relativeTo: Date())
    }
}

#Preview {
    GateView()
        .environment(AppState())
}
