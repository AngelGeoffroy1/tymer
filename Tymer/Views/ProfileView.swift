//
//  ProfileView.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI
import PhotosUI
import Auth

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @StateObject private var supabase = SupabaseManager.shared

    @State private var dragOffset: CGFloat = 0
    @State private var cardsAppeared = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isUploadingAvatar = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        ZStack {
            Color.tymerBlack
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerSection

                    // Profile Section
                    profileSection

                    // Digest Section
                    digestSection

                    Spacer(minLength: 40)
                }
            }
        }
        .offset(x: dragOffset)
        .gesture(swipeGesture)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                cardsAppeared = true
            }
        }
        .onDisappear {
            cardsAppeared = false
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage {
                Task {
                    await uploadAvatar(image)
                }
            }
        }
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onChanged { value in
                if value.translation.width > 0 {
                    dragOffset = value.translation.width * 0.4
                }
            }
            .onEnded { value in
                if value.translation.width > 80 {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        appState.navigate(to: .gate)
                    }
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    dragOffset = 0
                }
            }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14))
                Text("Portail")
                    .font(.funnelLight(14))
            }
            .foregroundColor(.tymerGray)
            .onTapGesture {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    appState.navigate(to: .gate)
                }
            }

            Spacer()

            Text("Mon Profil")
                .font(.tymerSubheadline)
                .foregroundColor(.tymerWhite)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        VStack(spacing: 20) {
            // Avatar
            ZStack {
                if let avatarUrl = supabase.currentProfile?.avatarUrl,
                   let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            avatarPlaceholder
                                .overlay(ProgressView().tint(.tymerWhite))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            avatarPlaceholder
                        @unknown default:
                            avatarPlaceholder
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    avatarPlaceholder
                }

                // Edit button overlay
                if isUploadingAvatar {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 100, height: 100)
                        .overlay(ProgressView().tint(.tymerWhite))
                }
            }
            .onTapGesture {
                showImagePicker = true
            }
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.tymerWhite)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.tymerBlack)
                    )
                    .offset(x: 4, y: 4)
            }

            // User Info
            VStack(spacing: 8) {
                Text(supabase.currentProfile?.firstName ?? appState.currentUser.firstName)
                    .font(.funnelSemiBold(28))
                    .foregroundColor(.tymerWhite)

                if let email = supabase.currentSession?.user.email {
                    Text(email)
                        .font(.funnelLight(14))
                        .foregroundColor(.tymerGray)
                }
            }

            // Stats
            HStack(spacing: 40) {
                statItem(value: "\(appState.weeklyDigest.count)", label: "Moments")
                statItem(value: "\(appState.circle.count)", label: "Amis")
            }
            .padding(.top, 8)

            // Logout button
            Button {
                Task {
                    try? await supabase.signOut()
                    appState.navigate(to: .auth)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Déconnexion")
                }
                .font(.funnelLight(14))
                .foregroundColor(.red.opacity(0.8))
            }
            .padding(.top, 16)
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(supabase.currentProfile?.displayColor ?? appState.currentUser.avatarColor)
            .frame(width: 100, height: 100)
            .overlay(
                Text(supabase.currentProfile?.initials ?? appState.currentUser.initials)
                    .font(.funnelSemiBold(36))
                    .foregroundColor(.tymerWhite)
            )
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.funnelSemiBold(24))
                .foregroundColor(.tymerWhite)
            Text(label)
                .font(.funnelLight(12))
                .foregroundColor(.tymerGray)
        }
    }

    // MARK: - Digest Section

    private var digestSection: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("Mon Digest")
                    .font(.funnelSemiBold(20))
                    .foregroundColor(.tymerWhite)

                Spacer()

                Text(weekRangeString)
                    .font(.funnelLight(12))
                    .foregroundColor(.tymerGray)
            }
            .padding(.horizontal, 20)

            // Photo grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(appState.weeklyDigest.enumerated()), id: \.element.id) { index, moment in
                    MomentThumbnail(moment, size: thumbnailSize)
                        .scaleEffect(cardsAppeared ? 1.0 : 0.5)
                        .opacity(cardsAppeared ? 1.0 : 0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.7)
                            .delay(Double(index) * 0.05),
                            value: cardsAppeared
                        )
                }
            }
            .padding(.horizontal, 20)

            // Empty state
            if appState.weeklyDigest.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 40))
                        .foregroundColor(.tymerDarkGray)

                    Text("Aucun moment cette semaine")
                        .font(.funnelLight(14))
                        .foregroundColor(.tymerGray)
                }
                .padding(.vertical, 40)
            }
        }
    }

    private var thumbnailSize: CGFloat {
        (UIScreen.main.bounds.width - 40 - 16) / 3
    }

    private var weekRangeString: String {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) ?? today

        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "fr_FR")

        return "\(formatter.string(from: weekAgo)) - \(formatter.string(from: today))"
    }

    // MARK: - Actions

    private func uploadAvatar(_ image: UIImage) async {
        isUploadingAvatar = true
        defer { isUploadingAvatar = false }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        do {
            _ = try await supabase.uploadAvatar(imageData)
        } catch {
            print("Error uploading avatar: \(error)")
        }

        selectedImage = nil
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    self.parent.image = image as? UIImage
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environment(AppState())
}
