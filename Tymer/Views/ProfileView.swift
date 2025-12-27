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

    @State private var cardsAppeared = false
    @State private var showEditProfile = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isUploadingAvatar = false

    var onNavigateToFeed: (() -> Void)?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        ZStack {
            Color.tymerBlack
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    headerSection

                    // Profile Section
                    profileSection

                    // Timeline Section
                    timelineSection

                    // Digest Section
                    digestSection

                    Spacer(minLength: 40)

                    // Logout button at bottom of content
                    logoutSection
                }
                .frame(minHeight: UIScreen.main.bounds.height - 100)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                cardsAppeared = true
            }
        }
        .onDisappear {
            cardsAppeared = false
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet(
                showImagePicker: $showImagePicker,
                selectedImage: $selectedImage,
                isUploadingAvatar: $isUploadingAvatar
            )
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

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Button {
                onNavigateToFeed?()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12))
                    Text("Swipe")
                        .font(.funnelLight(12))
                }
                .foregroundColor(.tymerDarkGray)
            }

            Spacer()

            HStack(spacing: 12) {
                Text("Mon Profil")
                    .font(.tymerSubheadline)
                    .foregroundColor(.tymerWhite)

                Button {
                    showEditProfile = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.tymerWhite)
                        .frame(width: 32, height: 32)
                        .background(Color.tymerDarkGray.opacity(0.6))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        VStack(spacing: 20) {
            // Avatar + User Info (horizontal layout)
            HStack(spacing: 20) {
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
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                    } else {
                        avatarPlaceholder
                    }

                    // Loading overlay
                    if isUploadingAvatar {
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 80, height: 80)
                            .overlay(ProgressView().tint(.tymerWhite))
                    }
                }

                // User Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(supabase.currentProfile?.firstName ?? appState.currentUser.firstName)
                        .font(.funnelSemiBold(24))
                        .foregroundColor(.tymerWhite)

                    if let email = supabase.currentSession?.user.email {
                        Text(email)
                            .font(.funnelLight(13))
                            .foregroundColor(.tymerGray)
                    }

                    // Stats inline
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Text("\(appState.weeklyDigest.count)")
                                .font(.funnelSemiBold(16))
                                .foregroundColor(.tymerWhite)
                            Text("Moments")
                                .font(.funnelLight(12))
                                .foregroundColor(.tymerGray)
                        }
                        HStack(spacing: 4) {
                            Text("\(appState.circle.count)")
                                .font(.funnelSemiBold(16))
                                .foregroundColor(.tymerWhite)
                            Text("Amis")
                                .font(.funnelLight(12))
                                .foregroundColor(.tymerGray)
                        }
                    }
                    .padding(.top, 4)
                }

                Spacer()
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(supabase.currentProfile?.displayColor ?? appState.currentUser.avatarColor)
            .frame(width: 80, height: 80)
            .overlay(
                Text(supabase.currentProfile?.initials ?? appState.currentUser.initials)
                    .font(.funnelSemiBold(28))
                    .foregroundColor(.tymerWhite)
            )
    }

    // MARK: - Timeline Section

    /// Combine all moments (mine + friends) sorted by date
    private var allMoments: [Moment] {
        let combined = appState.weeklyDigest + appState.moments
        return combined.sorted { $0.capturedAt > $1.capturedAt }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text("Timeline")
                    .font(.funnelSemiBold(20))
                    .foregroundColor(.tymerWhite)

                Spacer()

                Text("\(allMoments.count) moments")
                    .font(.funnelLight(12))
                    .foregroundColor(.tymerGray)
            }
            .padding(.horizontal, 20)

            if allMoments.isEmpty {
                // Empty state
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 24))
                            .foregroundColor(.tymerDarkGray)
                        Text("Aucun moment")
                            .font(.funnelLight(12))
                            .foregroundColor(.tymerGray)
                    }
                    .padding(.vertical, 30)
                    Spacer()
                }
            } else {
                // Timeline scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack(alignment: .leading) {
                        // Wavy timeline line
                        TimelineWavyLine()
                            .stroke(
                                LinearGradient(
                                    colors: [.tymerDarkGray.opacity(0.3), .tymerDarkGray.opacity(0.6), .tymerDarkGray.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 2, lineCap: .round)
                            )
                            .frame(height: 140)

                        // Moments
                        HStack(spacing: 0) {
                            ForEach(Array(allMoments.prefix(15).enumerated()), id: \.element.id) { index, moment in
                                TimelineMomentCard(
                                    moment: moment,
                                    index: index,
                                    isCurrentUser: moment.author.id == appState.currentUser.id
                                )
                                .scaleEffect(cardsAppeared ? 1.0 : 0.6)
                                .opacity(cardsAppeared ? 1.0 : 0)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.7)
                                    .delay(Double(index) * 0.08),
                                    value: cardsAppeared
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                }
                .frame(height: 160)
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - My Moments Section

    private var digestSection: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("Mes moments")
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

                    Text("Tu n'as pas encore posté")
                        .font(.funnelLight(14))
                        .foregroundColor(.tymerGray)
                }
                .padding(.vertical, 40)
            }
        }
    }

    // MARK: - Logout Section

    private var logoutSection: some View {
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
        .padding(.vertical, 16)
        .padding(.bottom, 20)
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

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabase = SupabaseManager.shared

    @Binding var showImagePicker: Bool
    @Binding var selectedImage: UIImage?
    @Binding var isUploadingAvatar: Bool

    @State private var firstName: String = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tymerBlack
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Avatar Section
                        VStack(spacing: 16) {
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

                                if isUploadingAvatar {
                                    Circle()
                                        .fill(Color.black.opacity(0.5))
                                        .frame(width: 100, height: 100)
                                        .overlay(ProgressView().tint(.tymerWhite))
                                }
                            }

                            Button {
                                showImagePicker = true
                                dismiss()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 12))
                                    Text("Changer la photo")
                                        .font(.funnelLight(14))
                                }
                                .foregroundColor(.tymerWhite)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.tymerDarkGray)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.top, 20)

                        // Form Fields
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Prénom")
                                    .font(.funnelLight(12))
                                    .foregroundColor(.tymerGray)

                                TextField("", text: $firstName)
                                    .font(.funnelSemiBold(18))
                                    .foregroundColor(.tymerWhite)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Color.tymerDarkGray.opacity(0.5))
                                    .cornerRadius(12)
                            }

                            if let email = supabase.currentSession?.user.email {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Email")
                                        .font(.funnelLight(12))
                                        .foregroundColor(.tymerGray)

                                    Text(email)
                                        .font(.funnelLight(16))
                                        .foregroundColor(.tymerGray)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.tymerDarkGray.opacity(0.3))
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Modifier le profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.tymerBlack, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(.tymerGray)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await saveProfile()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(.tymerWhite)
                        } else {
                            Text("Enregistrer")
                                .foregroundColor(.tymerWhite)
                        }
                    }
                    .disabled(isSaving || firstName.isEmpty)
                }
            }
            .onAppear {
                firstName = supabase.currentProfile?.firstName ?? ""
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(supabase.currentProfile?.displayColor ?? .blue)
            .frame(width: 100, height: 100)
            .overlay(
                Text(supabase.currentProfile?.initials ?? "?")
                    .font(.funnelSemiBold(36))
                    .foregroundColor(.tymerWhite)
            )
    }

    private func saveProfile() async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await supabase.updateProfile(firstName: firstName)
            dismiss()
        } catch {
            print("Error saving profile: \(error)")
        }
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

// MARK: - Timeline Components

/// Wavy line shape for timeline background
struct TimelineWavyLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.height / 2
        let amplitude: CGFloat = 15
        let wavelength: CGFloat = 80

        path.move(to: CGPoint(x: 0, y: midY))

        var x: CGFloat = 0
        while x < rect.width {
            let y = midY + sin(x / wavelength * .pi * 2) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
            x += 1
        }

        return path
    }
}

/// Individual moment card for timeline
struct TimelineMomentCard: View {
    let moment: Moment
    let index: Int
    let isCurrentUser: Bool

    private let cardSize: CGFloat = 70
    private let rotationAngles: [Double] = [-8, 5, -3, 7, -5, 4, -6, 8, -4, 6, -7, 3, -5, 8, -3]

    var body: some View {
        VStack(spacing: 6) {
            // Date label
            Text(dateLabel)
                .font(.funnelLight(9))
                .foregroundColor(.tymerGray)
                .opacity(index % 2 == 0 ? 1 : 0)

            // Photo card with rotation
            ZStack {
                // Shadow/glow effect
                RoundedRectangle(cornerRadius: 8)
                    .fill(isCurrentUser ? Color.tymerWhite.opacity(0.1) : moment.author.avatarColor.opacity(0.2))
                    .frame(width: cardSize, height: cardSize)
                    .blur(radius: 8)

                // Photo
                Group {
                    if let imageName = moment.imageName,
                       let uiImage = PhotoLoader.loadImage(named: imageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        placeholderView
                    }
                }
                .frame(width: cardSize, height: cardSize)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isCurrentUser ? Color.tymerWhite.opacity(0.3) : moment.author.avatarColor.opacity(0.5),
                            lineWidth: 2
                        )
                )
                .rotationEffect(.degrees(rotationAngles[index % rotationAngles.count]))

                // Author badge
                Circle()
                    .fill(moment.author.avatarColor)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Text(moment.author.initials)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.tymerBlack, lineWidth: 2)
                    )
                    .offset(x: cardSize/2 - 8, y: -cardSize/2 + 8)
            }
            .frame(width: cardSize + 20, height: cardSize + 20)
            .offset(y: index % 2 == 0 ? -10 : 10)

            // Time label
            Text(moment.timeString)
                .font(.funnelLight(9))
                .foregroundColor(.tymerDarkGray)
                .opacity(index % 2 == 1 ? 1 : 0)
        }
        .frame(width: 90)
    }

    private var placeholderView: some View {
        Rectangle()
            .fill(moment.placeholderColor)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))
            )
    }

    private var dateLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(moment.capturedAt) {
            return "Auj."
        } else if calendar.isDateInYesterday(moment.capturedAt) {
            return "Hier"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            formatter.locale = Locale(identifier: "fr_FR")
            return formatter.string(from: moment.capturedAt).capitalized
        }
    }
}

#Preview {
    ProfileView()
        .environment(AppState())
}
