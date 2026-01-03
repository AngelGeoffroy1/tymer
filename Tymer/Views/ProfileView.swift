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
    @State private var selectedMoment: Moment?
    @State private var showMomentDetail = false

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
            .blur(radius: showMomentDetail ? 10 : 0)

            // Moment detail overlay
            if showMomentDetail, let moment = selectedMoment {
                MomentDetailOverlay(moment: moment, isPresented: $showMomentDetail)
                    .transition(.opacity)
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
        .onChange(of: showMomentDetail) { _, isShowing in
            if !isShowing {
                selectedMoment = nil
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showMomentDetail)
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
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        selectedMoment = moment
                                        showMomentDetail = true
                                    }
                                }
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
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedMoment = moment
                                showMomentDetail = true
                            }
                        }
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
                    if let imagePath = moment.imageName {
                        if PhotoLoader.isSupabasePath(imagePath) {
                            SupabaseImage(path: imagePath, height: cardSize)
                        } else if let uiImage = PhotoLoader.loadImage(named: imagePath) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            placeholderView
                        }
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

// MARK: - Moment Detail Overlay

struct MomentDetailOverlay: View {
    let moment: Moment
    @Binding var isPresented: Bool
    @Environment(AppState.self) private var appState

    @State private var dragOffset: CGFloat = 0
    @State private var cardScale: CGFloat = 0.8
    @State private var cardOpacity: Double = 0
    @State private var backgroundOpacity: Double = 0
    @State private var loadedImage: UIImage?
    @State private var isImageLoading = true
    @State private var imageBlurRadius: CGFloat = 20

    // Portrait ratio 3:4 pour les photos
    private let cardWidth: CGFloat = UIScreen.main.bounds.width - 48
    private var photoHeight: CGFloat { cardWidth * 4 / 3 }

    var body: some View {
        ZStack {
            // Blurred background
            Color.black
                .opacity(backgroundOpacity * 0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissOverlay()
                }

            // Card content
            VStack(spacing: 0) {
                // Close button - aligned with card width
                HStack {
                    Spacer()
                    Button {
                        dismissOverlay()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.tymerWhite)
                            .frame(width: 36, height: 36)
                            .background(Color.tymerDarkGray.opacity(0.8))
                            .clipShape(Circle())
                    }
                }
                .frame(width: cardWidth)
                .padding(.bottom, 12)

                // Main card - fixed width
                VStack(spacing: 0) {
                    // Photo section - Portrait ratio
                    ZStack(alignment: .bottomLeading) {
                        // Photo with blur loading effect
                        photoContentView
                            .frame(width: cardWidth, height: photoHeight)
                            .clipped()

                        // Gradient overlay
                        LinearGradient(
                            colors: [.clear, .clear, .black.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(width: cardWidth, height: 120)

                        // Author info
                        HStack(spacing: 12) {
                            FriendAvatar(moment.author, size: 40)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(moment.author.firstName)
                                    .font(.funnelSemiBold(16))
                                    .foregroundColor(.tymerWhite)

                                Text(moment.relativeTimeString)
                                    .font(.funnelLight(12))
                                    .foregroundColor(.tymerGray)
                            }

                            Spacer()

                            // Date/time badge
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(dateString)
                                    .font(.funnelLight(11))
                                    .foregroundColor(.tymerGray)
                                Text(moment.timeString)
                                    .font(.funnelSemiBold(14))
                                    .foregroundColor(.tymerWhite)
                            }
                        }
                        .padding(16)
                    }
                    .frame(width: cardWidth)

                    // Reactions section
                    reactionsSection
                }
                .frame(width: cardWidth)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.tymerDarkGray.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 10)
            }
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
            .offset(y: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 100 {
                            dismissOverlay()
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                cardScale = 1.0
                cardOpacity = 1.0
                backgroundOpacity = 1.0
            }
            loadImageAsync()
        }
    }

    // MARK: - Photo Content with Blur Loading

    @ViewBuilder
    private var photoContentView: some View {
        ZStack {
            // Placeholder gradient always visible behind
            LinearGradient(
                colors: [moment.placeholderColor.opacity(0.6), moment.placeholderColor.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Loaded image with blur effect
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: imageBlurRadius)
            } else if let imagePath = moment.imageName,
                      !PhotoLoader.isSupabasePath(imagePath),
                      let uiImage = PhotoLoader.loadImage(named: imagePath) {
                // Local image - no loading needed
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }

            // Loading indicator
            if isImageLoading && moment.imageName != nil && PhotoLoader.isSupabasePath(moment.imageName!) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.tymerWhite)
            }
        }
    }

    // MARK: - Reactions Section

    // Hauteur fixe pour la section réactions
    private let reactionsFixedHeight: CGFloat = 160
    
    @ViewBuilder
    private var reactionsSection: some View {
        if !moment.reactions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 12))
                    Text("\(moment.reactions.count) réaction\(moment.reactions.count > 1 ? "s" : "")")
                        .font(.funnelSemiBold(14))
                }
                .foregroundColor(.tymerWhite)
                .padding(.top, 14)
                .padding(.horizontal, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 6) {
                        ForEach(moment.reactions) { reaction in
                            MomentReactionRow(reaction: reaction)
                        }

                        // End of reactions indicator
                        HStack {
                            Rectangle()
                                .fill(Color.tymerDarkGray.opacity(0.3))
                                .frame(height: 1)

                            Text("Fin des réactions")
                                .font(.funnelLight(10))
                                .foregroundColor(.tymerDarkGray)

                            Rectangle()
                                .fill(Color.tymerDarkGray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .frame(height: reactionsFixedHeight - 50)
            }
            .frame(height: reactionsFixedHeight)
            .background(Color.tymerBlack.opacity(0.95))
        } else {
            // No reactions message
            HStack {
                Spacer()
                VStack(spacing: 6) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 18))
                        .foregroundColor(.tymerDarkGray)
                    Text("Aucune réaction")
                        .font(.funnelLight(12))
                        .foregroundColor(.tymerGray)
                }
                .padding(.vertical, 20)
                Spacer()
            }
            .frame(height: 60)
            .background(Color.tymerBlack.opacity(0.95))
        }
    }

    // MARK: - Image Loading

    private func loadImageAsync() {
        guard let imagePath = moment.imageName else {
            isImageLoading = false
            return
        }

        // Skip for local images
        guard PhotoLoader.isSupabasePath(imagePath) else {
            isImageLoading = false
            return
        }

        // Check cache first
        if let cachedImage = ImageCache.shared.get(forKey: imagePath) {
            loadedImage = cachedImage
            isImageLoading = false
            withAnimation(.easeOut(duration: 0.3)) {
                imageBlurRadius = 0
            }
            return
        }

        // Load from Supabase
        guard let url = PhotoLoader.supabaseImageURL(for: imagePath) else {
            isImageLoading = false
            return
        }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    // Cache the image
                    ImageCache.shared.set(image, forKey: imagePath)

                    await MainActor.run {
                        loadedImage = image
                        isImageLoading = false
                        // Animate blur removal
                        withAnimation(.easeOut(duration: 0.4)) {
                            imageBlurRadius = 0
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isImageLoading = false
                }
            }
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: moment.capturedAt)
    }

    private func dismissOverlay() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            cardScale = 0.8
            cardOpacity = 0
            backgroundOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
        }
    }
}

// MARK: - Image Cache for faster loading

final class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 50
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB
    }

    func get(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func set(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

// MARK: - Moment Reaction Row (for overlay)

struct MomentReactionRow: View {
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

    private func waveformHeights(count: Int) -> [CGFloat] {
        if let waveform = reaction.waveformData, !waveform.isEmpty {
            if waveform.count == count {
                return waveform.map { CGFloat($0) }
            } else {
                return resampleWaveform(waveform, to: count).map { CGFloat($0) }
            }
        }

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
        let baseWidth: CGFloat = 100
        let maxExtraWidth: CGFloat = 80
        let durationRatio = min(duration / 3.0, 1.0)
        let totalWidth = baseWidth + (maxExtraWidth * durationRatio)
        let barCount = Int(12 + (12 * durationRatio))
        let heights = waveformHeights(count: barCount)

        HStack(spacing: 5) {
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
    ProfileView()
        .environment(AppState())
}
