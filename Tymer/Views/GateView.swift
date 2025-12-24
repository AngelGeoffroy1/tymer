//
//  GateView.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI

struct GateView: View {
    @Environment(AppState.self) private var appState
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.tymerBlack
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header avec gesture de navigation
                headerSection
                    .gesture(
                        DragGesture(minimumDistance: 30)
                            .onChanged { value in
                                dragOffset = value.translation.width * 0.5
                            }
                            .onEnded { value in
                                handleSwipe(value.translation.width)
                            }
                    )
                
                // Status bar
                windowStatusBar
                
                // Feed scrollable
                feedSection
            }
            
            // Indicateurs de swipe sur les bords
            HStack {
                // Bord gauche - vers Circle
                Color.clear
                    .frame(width: 20)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onChanged { value in
                                if value.translation.width > 0 {
                                    dragOffset = value.translation.width * 0.5
                                }
                            }
                            .onEnded { value in
                                handleSwipe(value.translation.width)
                            }
                    )
                
                Spacer()
                
                // Bord droit - vers Digest
                Color.clear
                    .frame(width: 20)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onChanged { value in
                                if value.translation.width < 0 {
                                    dragOffset = value.translation.width * 0.5
                                }
                            }
                            .onEnded { value in
                                handleSwipe(value.translation.width)
                            }
                    )
            }
        }
        .offset(x: dragOffset)
    }
    
    private func handleSwipe(_ translation: CGFloat) {
        if translation < -60 {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                appState.navigate(to: .digest)
            }
        } else if translation > 60 {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                appState.navigate(to: .circle)
            }
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            dragOffset = 0
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    appState.navigate(to: .circle)
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
                    appState.navigate(to: .digest)
                }
            }) {
                VStack(spacing: 2) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                    Text("Digest")
                        .font(.funnelLight(10))
                }
                .foregroundColor(.tymerGray)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.tymerBlack) // Pour capter les touches
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
            LazyVStack(spacing: 16) {
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
                }
                
                ForEach(appState.moments) { moment in
                    PostCard(
                        moment: moment,
                        isBlurred: !appState.isWindowOpen
                    )
                }
            }
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - My Capture Card
    private var myCaptureCard: some View {
        Group {
            if appState.hasPostedToday, let myMoment = appState.myTodayMoment {
                PostCard(moment: myMoment, isBlurred: false, isMyPost: true)
            } else {
                capturePromptCard
            }
        }
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
    @State private var recordingDuration: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            postHeader
            photoSection
            
            if !isBlurred && !isMyPost {
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
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 12)
    }
    
    private var photoSection: some View {
        ZStack {
            if let imageName = moment.imageName, let uiImage = PhotoLoader.loadImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 400)
                    .clipped()
                    .blur(radius: isBlurred ? 30 : 0)
            } else {
                MockPhotoPattern(
                    baseColor: moment.placeholderColor,
                    patternType: abs(moment.id.hashValue) % 4
                )
                .frame(height: 400)
                .blur(radius: isBlurred ? 30 : 0)
            }
            
            if isBlurred {
                VStack(spacing: 12) {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.tymerWhite)
                    Text("Visible pendant la fenêtre")
                        .font(.funnelSemiBold(13))
                        .foregroundColor(.tymerWhite)
                    Text("8h-9h • 19h-20h")
                        .font(.funnelLight(11))
                        .foregroundColor(.tymerGray)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.5))
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var actionsSection: some View {
        HStack(spacing: 12) {
            // Bouton vocal - tap pour start/stop
            Button {
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
            
            // Bouton texte
            Button {
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
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
    }
    
    private var reactionsPreview: some View {
        HStack(spacing: 8) {
            HStack(spacing: -8) {
                ForEach(moment.reactions.prefix(3)) { reaction in
                    FriendAvatar(reaction.author, size: 22)
                        .overlay(
                            Circle()
                                .stroke(Color.tymerBlack, lineWidth: 2)
                        )
                }
            }
            Text("\(moment.reactions.count) réaction\(moment.reactions.count > 1 ? "s" : "")")
                .font(.funnelLight(11))
                .foregroundColor(.tymerGray)
            Spacer()
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
            
            Text("Message à \(moment.author.firstName)")
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
        
        let duration = appState.stopVoiceRecording()
        
        if recordingDuration > 0.3 {
            appState.addVoiceReaction(to: moment, duration: max(duration, recordingDuration))
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

#Preview {
    GateView()
        .environment(AppState())
}
