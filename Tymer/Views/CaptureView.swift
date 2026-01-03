//
//  CaptureView.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI
import AVFoundation

struct CaptureView: View {
    @Environment(AppState.self) private var appState
    @StateObject private var cameraService = CameraService()
    @State private var showPreview = false
    @State private var capturedImage: UIImage?
    @State private var isLoadingCamera = true
    @State private var showPermissionAlert = false
    @State private var momentDescription: String = ""
    @FocusState private var isDescriptionFocused: Bool

    var body: some View {
        ZStack {
            Color.tymerBlack
                .ignoresSafeArea()

            if appState.hasPostedToday && !appState.isRetakingMoment {
                alreadyPostedContent
            } else if showPreview, let image = capturedImage {
                previewContent(image: image)
            } else {
                cameraContent
            }
        }
        .onAppear {
            cameraService.startSession()
        }
        .onDisappear {
            cameraService.stopSession()
            // Reset retake mode if user leaves without posting
            if appState.isRetakingMoment && capturedImage == nil {
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

            // Live camera preview - larger like BeReal
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
                    // Capture animation overlay
                    .overlay {
                        if cameraService.isCapturing {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.3))
                                .padding(.horizontal, 12)
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

            // "PHOTO" label - BeReal style
            Text("PHOTO")
                .font(.funnelSemiBold(14))
                .foregroundColor(.yellow)
                .tracking(1)

            Spacer()

            // Capture button
            captureButton
                .padding(.bottom, 40)
        }
    }

    private var captureButton: some View {
        Button(action: {
            triggerCapture()
        }) {
            ZStack {
                Circle()
                    .stroke(Color.tymerWhite, lineWidth: 4)
                    .frame(width: 80, height: 80)

                if cameraService.isCapturing {
                    // Loading state
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .tymerWhite))
                        .scaleEffect(1.2)
                } else {
                    Circle()
                        .fill(Color.tymerWhite)
                        .frame(width: 64, height: 64)
                }
            }
        }
        .disabled(!cameraService.permissionGranted || !cameraService.isSessionRunning || cameraService.isCapturing)
        .opacity(cameraService.permissionGranted && cameraService.isSessionRunning ? 1 : 0.5)
        .scaleEffect(cameraService.isCapturing ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: cameraService.isCapturing)
    }

    private func triggerCapture() {
        guard cameraService.permissionGranted else {
            showPermissionAlert = true
            return
        }

        guard !cameraService.isCapturing else { return }

        // Haptic feedback
        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator.impactOccurred()

        // Capture from live camera
        cameraService.capturePhoto()
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

    // MARK: - Preview Content
    private func previewContent(image: UIImage) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Reprendre") {
                        withAnimation {
                            showPreview = false
                            capturedImage = nil
                            momentDescription = ""
                        }
                        // Restart camera
                        cameraService.startSession()
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

                // Confirm button
                VStack(spacing: 16) {
                    TymerButton("Partager mon moment", style: .primary) {
                        sharePhoto()
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
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            // Stop camera when showing preview
            cameraService.stopSession()
        }
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
