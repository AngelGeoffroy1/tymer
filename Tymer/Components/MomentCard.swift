//
//  MomentCard.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI

// MARK: - Photo Loader Helper
struct PhotoLoader {
    /// Charge une image depuis le stockage local, les Assets ou le Bundle
    static func loadImage(named name: String) -> UIImage? {
        // D'abord essayer le stockage des moments capturés (images avec UUID)
        if let capturedImage = ImageStorageManager.shared.loadImage(withId: name) {
            return capturedImage
        }

        // Ensuite essayer les Assets
        if let image = UIImage(named: name) {
            return image
        }

        // Enfin essayer le bundle avec différentes extensions
        let extensions = ["JPG", "jpg", "PNG", "png", "jpeg", "JPEG"]
        for ext in extensions {
            if let path = Bundle.main.path(forResource: name, ofType: ext),
               let image = UIImage(contentsOfFile: path) {
                return image
            }
        }

        return nil
    }

    /// Returns the Supabase Storage URL for a moment image path
    static func supabaseImageURL(for path: String) -> URL? {
        return SupabaseManager.shared.getMomentImageURL(path)
    }

    /// Check if the path looks like a Supabase storage path (contains /)
    static func isSupabasePath(_ path: String) -> Bool {
        return path.contains("/") && !path.hasPrefix("/")
    }
}

// MARK: - Async Image View for Supabase
struct SupabaseImage: View {
    let path: String
    let height: CGFloat
    var blurRadius: CGFloat = 0

    @State private var loadedImage: UIImage?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: height)
                    .clipped()
                    .blur(radius: blurRadius)
            } else if isLoading {
                Rectangle()
                    .fill(Color.tymerDarkGray.opacity(0.3))
                    .frame(height: height)
                    .overlay(
                        ProgressView()
                            .tint(.tymerGray)
                    )
            } else {
                Rectangle()
                    .fill(Color.tymerDarkGray.opacity(0.3))
                    .frame(height: height)
            }
        }
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let url = PhotoLoader.supabaseImageURL(for: path) else {
            isLoading = false
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    loadedImage = image
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    isLoading = false
                }
            }
        } catch {
            print("Error loading image from Supabase: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// MARK: - Mock Photo Patterns (Fallback)
struct MockPhotoPattern: View {
    let baseColor: Color
    let patternType: Int
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [baseColor.opacity(0.6), baseColor.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            switch patternType % 4 {
            case 0:
                circlesPattern
            case 1:
                wavesPattern
            case 2:
                diagonalPattern
            default:
                dotsPattern
            }
        }
    }
    
    private var circlesPattern: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(baseColor.opacity(0.2))
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: geo.size.width * 0.3, y: -geo.size.height * 0.2)
                
                Circle()
                    .fill(baseColor.opacity(0.15))
                    .frame(width: geo.size.width * 0.4)
                    .offset(x: -geo.size.width * 0.2, y: geo.size.height * 0.3)
            }
        }
    }
    
    private var wavesPattern: some View {
        GeometryReader { geo in
            Path { path in
                let width = geo.size.width
                let height = geo.size.height
                let waveHeight: CGFloat = 30
                
                for i in 0..<5 {
                    let y = height * CGFloat(i + 1) / 6
                    path.move(to: CGPoint(x: 0, y: y))
                    
                    for x in stride(from: 0, to: width, by: 20) {
                        let relativeX = x / width
                        let offsetY = sin(relativeX * .pi * 2) * waveHeight
                        path.addLine(to: CGPoint(x: x, y: y + offsetY))
                    }
                }
            }
            .stroke(baseColor.opacity(0.2), lineWidth: 2)
        }
    }
    
    private var diagonalPattern: some View {
        GeometryReader { geo in
            Path { path in
                let spacing: CGFloat = 40
                let count = Int((geo.size.width + geo.size.height) / spacing)
                
                for i in 0..<count {
                    let offset = CGFloat(i) * spacing
                    path.move(to: CGPoint(x: offset, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: offset))
                }
            }
            .stroke(baseColor.opacity(0.15), lineWidth: 1)
        }
    }
    
    private var dotsPattern: some View {
        GeometryReader { geo in
            let cols = 8
            let rows = 12
            let dotSize: CGFloat = 8
            
            ForEach(0..<rows, id: \.self) { row in
                ForEach(0..<cols, id: \.self) { col in
                    Circle()
                        .fill(baseColor.opacity(0.2))
                        .frame(width: dotSize, height: dotSize)
                        .position(
                            x: geo.size.width * CGFloat(col + 1) / CGFloat(cols + 1),
                            y: geo.size.height * CGFloat(row + 1) / CGFloat(rows + 1)
                        )
                }
            }
        }
    }
}

// MARK: - Moment Card Component (Full Screen)
struct MomentCard: View {
    let moment: Moment
    var onReaction: (() -> Void)? = nil
    var onMessage: (() -> Void)? = nil
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Photo ou placeholder
                photoContent
                    .ignoresSafeArea()
                
                // Overlay gradient pour lisibilité
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 200)
                }
                .ignoresSafeArea()
                
                // Contenu
                VStack {
                    Spacer()
                    
                    // Info auteur
                    HStack(spacing: 12) {
                        FriendAvatar(moment.author, size: 44)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(moment.author.firstName)
                                .font(.funnelSemiBold(18))
                                .foregroundColor(.tymerWhite)
                            
                            Text(moment.relativeTimeString)
                                .font(.tymerCaption)
                                .foregroundColor(.tymerGray)
                        }
                        
                        Spacer()
                        
                        // Indicateur de réactions
                        if !moment.reactions.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.left.fill")
                                    .font(.system(size: 12))
                                Text("\(moment.reactions.count)")
                                    .font(.funnelLight(14))
                            }
                            .foregroundColor(.tymerGray)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    @ViewBuilder
    private var photoContent: some View {
        if let imagePath = moment.imageName {
            if PhotoLoader.isSupabasePath(imagePath) {
                SupabaseImage(path: imagePath, height: UIScreen.main.bounds.height)
            } else if let uiImage = PhotoLoader.loadImage(named: imagePath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                patternFallback
            }
        } else {
            patternFallback
        }
    }

    private var patternFallback: some View {
        MockPhotoPattern(
            baseColor: moment.placeholderColor,
            patternType: abs(moment.id.hashValue) % 4
        )
    }
}

// MARK: - Moment Thumbnail (Grid)
struct MomentThumbnail: View {
    let moment: Moment
    let size: CGFloat
    
    init(_ moment: Moment, size: CGFloat = 100) {
        self.moment = moment
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Photo ou pattern background
            thumbnailContent
            
            // Date pour le digest
            VStack {
                Spacer()
                Text(dayString)
                    .font(.funnelSemiBold(12))
                    .foregroundColor(.tymerWhite)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
                    .padding(8)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var thumbnailContent: some View {
        if let imagePath = moment.imageName {
            if PhotoLoader.isSupabasePath(imagePath) {
                SupabaseImage(path: imagePath, height: size)
                    .frame(width: size, height: size)
            } else if let uiImage = PhotoLoader.loadImage(named: imagePath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
            } else {
                placeholderGradient
            }
        } else {
            placeholderGradient
        }
    }

    private var placeholderGradient: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [moment.placeholderColor.opacity(0.6), moment.placeholderColor.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
    }
    
    private var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: moment.capturedAt).capitalized
    }
}

// MARK: - Feed End Card
struct FeedEndCard: View {
    var onDismiss: () -> Void
    @State private var checkmarkScale: CGFloat = 0.5
    @State private var checkmarkOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.tymerWhite.opacity(0.2), lineWidth: 2)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.tymerWhite)
                    .scaleEffect(checkmarkScale)
                    .opacity(checkmarkOpacity)
            }
            
            VStack(spacing: 12) {
                Text("Tu as tout vu")
                    .font(.tymerHeadline)
                    .foregroundColor(.tymerWhite)
                
                Text("À demain !")
                    .font(.tymerBody)
                    .foregroundColor(.tymerGray)
            }
            
            Spacer()
            
            TymerButton("Retour au portail", style: .secondary, action: onDismiss)
                .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tymerBackground()
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                checkmarkScale = 1.0
                checkmarkOpacity = 1.0
            }
        }
    }
}

#Preview("Moment Card") {
    MomentCard(moment: Moment.mockMoments()[0])
}

#Preview("Thumbnails") {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
        ForEach(Moment.mockWeeklyDigest()) { moment in
            MomentThumbnail(moment, size: 110)
        }
    }
    .padding()
    .tymerBackground()
}

#Preview("Feed End") {
    FeedEndCard(onDismiss: {})
}
