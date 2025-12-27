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
    @State private var flashAnimation = false
    @State private var showPermissionAlert = false
    @State private var momentDescription: String = ""
    @FocusState private var isDescriptionFocused: Bool

    var body: some View {
        ZStack {
            Color.tymerBlack
                .ignoresSafeArea()

            if appState.hasPostedToday {
                alreadyPostedContent
            } else if showPreview, let image = capturedImage {
                previewContent(image: image)
            } else {
                cameraContent
            }

            // Flash effect
            if flashAnimation {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .onAppear {
            cameraService.startSession()
        }
        .onDisappear {
            cameraService.stopSession()
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
            // Header
            HStack {
                TymerBackButton {
                    appState.navigate(to: .gate)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Spacer()

            // Live camera preview in frame
            ZStack {
                if cameraService.permissionGranted && cameraService.isSessionRunning {
                    // Live camera feed
                    CameraPreviewView(session: cameraService.session)
                        .frame(height: UIScreen.main.bounds.height * 0.55)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal, 20)
                } else {
                    // Placeholder while loading or permission denied
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.tymerDarkGray.opacity(0.3))
                        .frame(height: UIScreen.main.bounds.height * 0.55)
                        .padding(.horizontal, 20)
                        .overlay {
                            VStack(spacing: 16) {
                                if !cameraService.permissionGranted {
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
                                } else {
                                    ProgressView()
                                        .tint(.tymerWhite)
                                    Text("Chargement de la caméra...")
                                        .font(.funnelLight(14))
                                        .foregroundColor(.tymerGray)
                                }
                            }
                        }
                }
            }

            Spacer()

            // Capture button
            captureButton
                .padding(.bottom, 60)
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

                Circle()
                    .fill(Color.tymerWhite)
                    .frame(width: 64, height: 64)
            }
        }
        .disabled(!cameraService.permissionGranted || !cameraService.isSessionRunning)
        .opacity(cameraService.permissionGranted && cameraService.isSessionRunning ? 1 : 0.5)
    }

    private func triggerCapture() {
        guard cameraService.permissionGranted else {
            showPermissionAlert = true
            return
        }

        // Haptic feedback
        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator.impactOccurred()

        // Capture from live camera
        cameraService.capturePhoto()
    }

    private func handleCapturedImage(_ image: UIImage) {
        // Flash effect
        withAnimation(.easeIn(duration: 0.1)) {
            flashAnimation = true
        }

        capturedImage = image

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.2)) {
                flashAnimation = false
            }
            withAnimation {
                showPreview = true
            }
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
                        withAnimation {
                            showPreview = false
                            capturedImage = nil
                            momentDescription = ""
                        }
                        // Restart camera
                        cameraService.startSession()
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
