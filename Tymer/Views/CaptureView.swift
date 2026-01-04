//
//  CaptureView.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI
import AVFoundation
import AVKit

struct CaptureView: View {
    @Environment(AppState.self) private var appState
    @StateObject private var cameraService = CameraService()
    @State private var showPreview = false
    @State private var capturedImage: UIImage?
    @State private var capturedVideoURL: URL?
    @State private var capturedVideoDuration: TimeInterval = 0
    @State private var isLoadingCamera = true
    @State private var showPermissionAlert = false
    @State private var momentDescription: String = ""
    @FocusState private var isDescriptionFocused: Bool
    @State private var dragOffset: CGFloat = 0
    @State private var showModeHint = true

    var body: some View {
        ZStack {
            Color.tymerBlack
                .ignoresSafeArea()

            if appState.hasPostedToday && !appState.isRetakingMoment {
                alreadyPostedContent
            } else if showPreview {
                if let image = capturedImage {
                    photoPreviewContent(image: image)
                } else if let videoURL = capturedVideoURL {
                    videoPreviewContent(videoURL: videoURL)
                }
            } else {
                cameraContent
            }
        }
        .onAppear {
            cameraService.startSession()
            // Cacher l'indice après 3 secondes
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showModeHint = false
                }
            }
        }
        .onDisappear {
            cameraService.stopSession()
            // Reset retake mode if user leaves without posting
            if appState.isRetakingMoment && capturedImage == nil && capturedVideoURL == nil {
                appState.isRetakingMoment = false
                appState.momentToReplace = nil
            }
        }
        .onChange(of: cameraService.capturedImage) { _, newImage in
            if let image = newImage {
                handleCapturedImage(image)
                cameraService.capturedImage = nil
            }
        }
        .onChange(of: cameraService.capturedVideoURL) { _, newVideoURL in
            if let videoURL = newVideoURL {
                handleCapturedVideo(videoURL, duration: cameraService.capturedVideoDuration)
                cameraService.capturedVideoURL = nil
            }
        }
        .alert("Accès à la caméra refusé", isPresented: $showPermissionAlert) {
            Button("Ouvrir les réglages") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Annuler", role: .cancel) {
                appState.navigate(to: .gate)
            }
        } message: {
            Text("Pour capturer ton moment, autorise l'accès à la caméra dans les réglages de ton iPhone.")
        }
    }

    // MARK: - Camera Content
    private var cameraContent: some View {
        VStack(spacing: 0) {
            // Header - BeReal style
            ZStack {
                // Back button on left
                HStack {
                    Button {
                        appState.navigate(to: .gate)
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.tymerWhite)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Color.tymerDarkGray))
                    }
                    Spacer()
                }

                // Tymer. centered
                Text("Tymer.")
                    .font(.funnelSemiBold(22))
                    .foregroundColor(.tymerWhite)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()
                .frame(height: 20)

            // Live camera preview - with swipe gesture
            ZStack {
                // Camera feed (always present when permission granted)
                if cameraService.permissionGranted {
                    CameraPreviewView(
                        session: cameraService.session,
                        onDoubleTap: {
                            cameraService.switchCamera()
                        },
                        onPinchOut: {
                            cameraService.switchToUltraWide()
                        }
                    )
                    .frame(height: UIScreen.main.bounds.height * 0.62)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 12)
                    .offset(x: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // Limiter le drag
                                let translation = value.translation.width
                                dragOffset = max(-50, min(50, translation))
                            }
                            .onEnded { value in
                                let threshold: CGFloat = 40
                                
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    dragOffset = 0
                                }
                                
                                // Swipe de droite à gauche = mode vidéo
                                if value.translation.width < -threshold && cameraService.captureMode == .photo {
                                    cameraService.toggleCaptureMode()
                                }
                                // Swipe de gauche à droite = mode photo
                                else if value.translation.width > threshold && cameraService.captureMode == .video {
                                    cameraService.toggleCaptureMode()
                                }
                            }
                    )
                    // Blur overlay while loading
                    .overlay {
                        if !cameraService.isSessionRunning || isLoadingCamera {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .padding(.horizontal, 12)
                                .overlay {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(1.2)
                                }
                        }
                    }
                    .overlay(alignment: .bottom) {
                        // Bottom controls overlay - BeReal style (only when ready)
                        if cameraService.isSessionRunning && !isLoadingCamera {
                            HStack {
                                // Flash button
                                Button {
                                    cameraService.toggleFlash()
                                } label: {
                                    Image(systemName: cameraService.flashMode.iconName)
                                        .font(.system(size: 18))
                                        .foregroundColor(cameraService.flashMode == .off ? .white : .yellow)
                                        .frame(width: 44, height: 44)
                                }
                                .opacity(cameraService.currentCameraPosition == .back ? 1 : 0.3)
                                .disabled(cameraService.currentCameraPosition != .back)

                                Spacer()

                                // Zoom button - centered (smaller size, more opacity)
                                if cameraService.currentCameraPosition == .back {
                                    Button {
                                        cameraService.switchToUltraWide()
                                    } label: {
                                        Text(cameraService.isUltraWideActive ? "0.5x" : "1x")
                                            .font(.funnelSemiBold(12))
                                            .foregroundColor(.white)
                                            .frame(width: 36, height: 36)
                                            .background(
                                                Circle()
                                                    .fill(Color.black.opacity(0.7))
                                            )
                                    }
                                }

                                Spacer()

                                // Switch camera button
                                Button {
                                    cameraService.switchCamera()
                                } label: {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)
                        }
                    }
                    // Mode hint overlay
                    .overlay(alignment: .top) {
                        if showModeHint && cameraService.isSessionRunning && !isLoadingCamera {
                            HStack(spacing: 8) {
                                Image(systemName: "hand.draw")
                                    .font(.system(size: 14))
                                Text("Glisse pour changer de mode")
                                    .font(.funnelLight(12))
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.black.opacity(0.5)))
                            .padding(.top, 16)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    // Capture animation overlay
                    .overlay {
                        if cameraService.isCapturing || cameraService.isRecordingVideo {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.3))
                                .padding(.horizontal, 12)
                        }
                    }
                    // Recording progress border
                    .overlay {
                        if cameraService.isRecordingVideo {
                            RoundedRectangle(cornerRadius: 20)
                                .trim(from: 0, to: cameraService.videoRecordingProgress)
                                .stroke(Color.red, lineWidth: 4)
                                .padding(.horizontal, 12)
                                .animation(.linear(duration: 0.05), value: cameraService.videoRecordingProgress)
                        }
                    }
                } else {
                    // Permission denied placeholder
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.tymerDarkGray.opacity(0.3))
                        .frame(height: UIScreen.main.bounds.height * 0.62)
                        .padding(.horizontal, 12)
                        .overlay {
                            VStack(spacing: 16) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 48, weight: .light))
                                    .foregroundColor(.tymerGray)

                                Text("Accès caméra requis")
                                    .font(.tymerBody)
                                    .foregroundColor(.tymerGray)

                                Button("Autoriser l'accès") {
                                    cameraService.checkPermission()
                                    if !cameraService.permissionGranted {
                                        showPermissionAlert = true
                                    }
                                }
                                .font(.funnelSemiBold(14))
                                .foregroundColor(.tymerWhite)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(Color.tymerDarkGray))
                            }
                        }
                }
            }
            .onChange(of: cameraService.isSessionRunning) { _, isRunning in
                if isRunning {
                    // Small delay to let camera stabilize before removing blur
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isLoadingCamera = false
                        }
                    }
                } else {
                    isLoadingCamera = true
                }
            }

            Spacer()
                .frame(height: 16)

            // Mode selector - swipeable
            modeSelector

            Spacer()

            // Capture button
            captureButton
                .padding(.bottom, 40)
        }
    }

    // MARK: - Mode Selector
    private var modeSelector: some View {
        HStack(spacing: 24) {
            ForEach(CaptureMode.allCases, id: \.self) { mode in
                Button {
                    if cameraService.captureMode != mode {
                        cameraService.toggleCaptureMode()
                    }
                } label: {
                    Text(mode.displayName)
                        .font(.funnelSemiBold(14))
                        .foregroundColor(cameraService.captureMode == mode ? mode.accentColor : .tymerGray)
                        .tracking(1)
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: cameraService.captureMode)
    }

    // MARK: - Capture Button
    private var captureButton: some View {
        Button(action: {
            triggerCapture()
        }) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color.tymerWhite, lineWidth: 4)
                    .frame(width: 80, height: 80)

                if cameraService.isCapturing || (cameraService.isRecordingVideo && cameraService.captureMode == .video) {
                    // Recording state - show red circle
                    if cameraService.captureMode == .video {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red)
                            .frame(width: 32, height: 32)
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .tymerWhite))
                            .scaleEffect(1.2)
                    }
                } else {
                    // Normal state
                    if cameraService.captureMode == .photo {
                        Circle()
                            .fill(Color.tymerWhite)
                            .frame(width: 64, height: 64)
                    } else {
                        // Video mode - red center
                        Circle()
                            .fill(Color.red)
                            .frame(width: 64, height: 64)
                    }
                }
            }
        }
        .disabled(!cameraService.permissionGranted || !cameraService.isSessionRunning || cameraService.isCapturing)
        .opacity(cameraService.permissionGranted && cameraService.isSessionRunning ? 1 : 0.5)
        .scaleEffect(cameraService.isCapturing || cameraService.isRecordingVideo ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: cameraService.isCapturing)
        .animation(.easeInOut(duration: 0.15), value: cameraService.isRecordingVideo)
    }

    private func triggerCapture() {
        guard cameraService.permissionGranted else {
            showPermissionAlert = true
            return
        }

        if cameraService.captureMode == .photo {
            guard !cameraService.isCapturing else { return }
            
            // Haptic feedback
            let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
            impactGenerator.impactOccurred()

            // Capture from live camera
            cameraService.capturePhoto()
        } else {
            // Video mode
            if cameraService.isRecordingVideo {
                cameraService.stopVideoRecording()
            } else {
                cameraService.startVideoRecording()
            }
        }
    }

    private func handleCapturedImage(_ image: UIImage) {
        capturedImage = image

        // Smooth transition to preview
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showPreview = true
            }

            // Success haptic
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    private func handleCapturedVideo(_ videoURL: URL, duration: TimeInterval) {
        capturedVideoURL = videoURL
        capturedVideoDuration = duration

        // Smooth transition to preview
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showPreview = true
            }

            // Success haptic
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    // MARK: - Photo Preview Content
    private func photoPreviewContent(image: UIImage) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Reprendre") {
                        resetPreview()
                    }
                    .font(.funnelLight(16))
                    .foregroundColor(.tymerWhite)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Preview with actual captured image
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: UIScreen.main.bounds.height * 0.45)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal, 20)
                }
                .padding(.top, 16)

                // Description field
                descriptionField

                // Confirm button
                confirmButtons(isVideo: false)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            // Stop camera when showing preview
            cameraService.stopSession()
        }
    }

    // MARK: - Video Preview Content
    private func videoPreviewContent(videoURL: URL) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Reprendre") {
                        resetPreview()
                    }
                    .font(.funnelLight(16))
                    .foregroundColor(.tymerWhite)

                    Spacer()
                    
                    // Video duration badge
                    HStack(spacing: 4) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 12))
                        Text(String(format: "%.1fs", capturedVideoDuration))
                            .font(.funnelSemiBold(12))
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.red.opacity(0.2)))
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Video preview player
                VideoPlayerView(url: videoURL)
                    .frame(height: UIScreen.main.bounds.height * 0.45)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // Description field
                descriptionField

                // Confirm button
                confirmButtons(isVideo: true)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            // Stop camera when showing preview
            cameraService.stopSession()
        }
    }

    // MARK: - Shared Components
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ajoute une description")
                .font(.funnelLight(12))
                .foregroundColor(.tymerGray)

            TextField("", text: $momentDescription, prompt: Text("Décris ton moment...").foregroundColor(.tymerDarkGray), axis: .vertical)
                .font(.funnelLight(14))
                .foregroundColor(.tymerWhite)
                .lineLimit(3...5)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.tymerDarkGray.opacity(0.3))
                )
                .focused($isDescriptionFocused)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private func confirmButtons(isVideo: Bool) -> some View {
        VStack(spacing: 16) {
            TymerButton("Partager mon moment", style: .primary) {
                if isVideo {
                    shareVideo()
                } else {
                    sharePhoto()
                }
            }

            Button("Annuler") {
                // Retour direct à GateView
                appState.navigate(to: .gate)
            }
            .buttonStyle(.tymerGhost)
        }
        .padding(.top, 24)
        .padding(.bottom, 60)
    }

    private func resetPreview() {
        withAnimation {
            showPreview = false
            capturedImage = nil
            capturedVideoURL = nil
            capturedVideoDuration = 0
            momentDescription = ""
        }
        // Restart camera
        cameraService.startSession()
    }

    // MARK: - Already Posted Content
    private var alreadyPostedContent: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.tymerWhite.opacity(0.2), lineWidth: 2)
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.tymerWhite)
            }

            VStack(spacing: 12) {
                Text("Moment partagé")
                    .font(.tymerHeadline)
                    .foregroundColor(.tymerWhite)

                Text("Tu as déjà capturé ton moment aujourd'hui.\nÀ demain !")
                    .font(.tymerBody)
                    .foregroundColor(.tymerGray)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            TymerButton("Retour au portail", style: .secondary) {
                appState.navigate(to: .gate)
            }
            .padding(.bottom, 60)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Actions
    private func sharePhoto() {
        guard let image = capturedImage else { return }

        // Poster le moment avec l'image réelle et la description
        appState.postMomentWithImage(image, description: momentDescription)

        // Haptic success
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Reset
        momentDescription = ""

        // Retour au portail
        appState.navigate(to: .gate)
    }

    private func shareVideo() {
        guard let videoURL = capturedVideoURL else { return }

        // Poster le moment avec la vidéo et la description
        appState.postMomentWithVideo(videoURL, duration: capturedVideoDuration, description: momentDescription)

        // Haptic success
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Reset
        momentDescription = ""

        // Retour au portail
        appState.navigate(to: .gate)
    }
}

// MARK: - Video Player View (Optimized, Looping, Muted by default)
struct VideoPlayerView: View {
    let url: URL
    @State private var player: AVPlayer?
    @State private var isMuted = true
    @State private var isPlayerReady = false

    var body: some View {
        ZStack {
            if let player = player {
                // Custom video layer with proper aspect fill
                VideoPlayerLayerView(player: player)
                    .opacity(isPlayerReady ? 1 : 0)
            }

            // Loading placeholder
            if !isPlayerReady {
                Color.tymerDarkGray
                    .overlay {
                        ProgressView()
                            .tint(.white)
                    }
            }

            // Mute/Unmute button
            if isPlayerReady {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            isMuted.toggle()
                            player?.isMuted = isMuted
                        } label: {
                            Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        .padding(12)
                    }
                }
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
    }

    private func setupPlayer() {
        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.isMuted = isMuted

        // Observe when player is ready
        playerItem.addObserver(CapturePlayerItemObserver.shared, forKeyPath: "status", options: [.new], context: nil)
        CapturePlayerItemObserver.shared.onReady = {
            DispatchQueue.main.async {
                self.isPlayerReady = true
                newPlayer.play()
            }
        }

        // Loop video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            newPlayer.seek(to: .zero)
            newPlayer.play()
        }

        player = newPlayer

        // Start playing immediately if already ready
        if playerItem.status == .readyToPlay {
            isPlayerReady = true
            newPlayer.play()
        }
    }
}

// MARK: - Capture Player Item Observer
private class CapturePlayerItemObserver: NSObject {
    static let shared = CapturePlayerItemObserver()
    var onReady: (() -> Void)?

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status", let item = object as? AVPlayerItem, item.status == .readyToPlay {
            onReady?()
        }
    }
}

#Preview {
    CaptureView()
        .environment(AppState())
}

#Preview("Already Posted") {
    let state = AppState()
    state.hasPostedToday = true
    return CaptureView()
        .environment(state)
}
