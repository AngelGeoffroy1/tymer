//
//  Models.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import Foundation
import SwiftUI

// MARK: - User Model
struct User: Identifiable, Equatable {
    let id: UUID
    let firstName: String
    let avatarColor: Color
    
    init(id: UUID = UUID(), firstName: String, avatarColor: Color = .tymerGray) {
        self.id = id
        self.firstName = firstName
        self.avatarColor = avatarColor
    }
    
    /// Initiales pour l'avatar
    var initials: String {
        String(firstName.prefix(1)).uppercased()
    }
}

// MARK: - Moment Model (Post du jour)
struct Moment: Identifiable {
    let id: UUID
    let author: User
    let imageName: String?  // Nom de l'image dans MockPhotos ou ID d'image capturée
    let placeholderColor: Color
    let capturedAt: Date
    var description: String?  // Description du moment
    var reactions: [Reaction]

    init(
        id: UUID = UUID(),
        author: User,
        imageName: String? = nil,
        placeholderColor: Color = .tymerDarkGray,
        capturedAt: Date = Date(),
        description: String? = nil,
        reactions: [Reaction] = []
    ) {
        self.id = id
        self.author = author
        self.imageName = imageName
        self.placeholderColor = placeholderColor
        self.capturedAt = capturedAt
        self.description = description
        self.reactions = reactions
    }
    
    /// Heure formatée
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: capturedAt)
    }
    
    /// "Il y a X heures/minutes"
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.localizedString(for: capturedAt, relativeTo: Date())
    }
}

// MARK: - Reaction Model
struct Reaction: Identifiable {
    let id: UUID
    let author: User
    let type: ReactionType
    let createdAt: Date
    let voicePath: String?  // Chemin vers le fichier audio dans Supabase Storage
    let waveformData: [Float]?  // Données de forme d'onde pour l'affichage

    init(id: UUID = UUID(), author: User, type: ReactionType, createdAt: Date = Date(), voicePath: String? = nil, waveformData: [Float]? = nil) {
        self.id = id
        self.author = author
        self.type = type
        self.createdAt = createdAt
        self.voicePath = voicePath
        self.waveformData = waveformData
    }
}

enum ReactionType {
    case voice(duration: TimeInterval) // Max 3 secondes
    case text(String)
    
    var displayText: String {
        switch self {
        case .voice(let duration):
            return "🎤 \(Int(duration))s"
        case .text(let message):
            return message
        }
    }
}

// MARK: - Time Window
struct TimeWindow: Equatable {
    let start: Int // Heure de début (0-23)
    let end: Int   // Heure de fin (0-23)
    let label: String
    let displayTime: String // Format: "08H-09H"

    init(start: Int, end: Int, label: String, displayTime: String? = nil) {
        self.start = start
        self.end = end
        self.label = label
        self.displayTime = displayTime ?? String(format: "%02dH-%02dH", start, end)
    }

    /// Fenêtres par défaut (utilisées uniquement si Supabase n'est pas disponible)
    static let morning = TimeWindow(start: 8, end: 9, label: "Matin", displayTime: "08H-09H")
    static let evening = TimeWindow(start: 19, end: 20, label: "Soir", displayTime: "19H-20H")
    static let defaultWindows: [TimeWindow] = [.morning, .evening]

    /// Vérifie si l'heure actuelle est dans cette fenêtre
    func isOpen(at date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        return hour >= start && hour < end
    }

    /// Temps restant jusqu'à la fermeture (si ouverte)
    func remainingTime(at date: Date = Date()) -> TimeInterval? {
        guard isOpen(at: date) else { return nil }
        let calendar = Calendar.current
        var endComponents = calendar.dateComponents([.year, .month, .day], from: date)
        endComponents.hour = end
        endComponents.minute = 0
        guard let endDate = calendar.date(from: endComponents) else { return nil }
        return endDate.timeIntervalSince(date)
    }
}

// MARK: - App Navigation
enum AppScreen: Equatable {
    case splash
    case auth
    case onboarding
    case gate
    case feed
    case capture
    case circle
    case profile       // Renamed from digest
    case messages
    case momentDetail(Moment)

    static func == (lhs: AppScreen, rhs: AppScreen) -> Bool {
        switch (lhs, rhs) {
        case (.splash, .splash),
             (.auth, .auth),
             (.onboarding, .onboarding),
             (.gate, .gate),
             (.feed, .feed),
             (.capture, .capture),
             (.circle, .circle),
             (.profile, .profile),
             (.messages, .messages):
            return true
        case (.momentDetail(let lhsMoment), .momentDetail(let rhsMoment)):
            return lhsMoment.id == rhsMoment.id
        default:
            return false
        }
    }
}

// MARK: - Mock Photo Names
/// Les photos dans le dossier MockPhotos
struct MockPhotoNames {
    static let feedPhotos = ["photo1", "photo2", "photo3", "photo4", "photo5", "photo6"]
    static let digestPhotos = ["photo1", "photo2", "photo3", "photo4", "photo5", "photo6", "photo1"]
}

// MARK: - Mock Data
extension User {
    static let mockUsers: [User] = [
        User(firstName: "Emma", avatarColor: .red),
        User(firstName: "Lucas", avatarColor: .blue),
        User(firstName: "Chloé", avatarColor: .green),
        User(firstName: "Hugo", avatarColor: .orange),
        User(firstName: "Léa", avatarColor: .purple),
        User(firstName: "Nathan", avatarColor: .pink),
        User(firstName: "Camille", avatarColor: .cyan),
        User(firstName: "Théo", avatarColor: .yellow),
        User(firstName: "Manon", avatarColor: .mint),
        User(firstName: "Raphaël", avatarColor: .indigo),
        User(firstName: "Jade", avatarColor: .teal),
        User(firstName: "Louis", avatarColor: .brown)
    ]
    
    static let currentUser = User(firstName: "Moi", avatarColor: .tymerWhite)
}

extension Moment {
    static func mockMoments() -> [Moment] {
        let calendar = Calendar.current
        return User.mockUsers.prefix(6).enumerated().map { index, user in
            let hoursAgo = Double(index) * 0.5
            let date = calendar.date(byAdding: .minute, value: -Int(hoursAgo * 60), to: Date()) ?? Date()
            
            // Utilise le nom de photo si disponible
            let photoName = index < MockPhotoNames.feedPhotos.count ? MockPhotoNames.feedPhotos[index] : nil
            
            return Moment(
                author: user,
                imageName: photoName,
                placeholderColor: user.avatarColor.opacity(0.4),
                capturedAt: date,
                reactions: index % 2 == 0 ? [
                    Reaction(author: User.mockUsers.randomElement()!, type: .text("Super ! 🔥")),
                    Reaction(author: User.mockUsers.randomElement()!, type: .voice(duration: 2))
                ] : []
            )
        }
    }
    
    static func mockWeeklyDigest() -> [Moment] {
        let calendar = Calendar.current
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
            let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .cyan]
            
            // Utilise le nom de photo si disponible
            let photoName = dayOffset < MockPhotoNames.digestPhotos.count ? MockPhotoNames.digestPhotos[dayOffset] : nil
            
            return Moment(
                author: User.currentUser,
                imageName: photoName,
                placeholderColor: colors[dayOffset].opacity(0.4),
                capturedAt: date
            )
        }
    }
}
