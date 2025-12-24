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
    let imageData: Data?
    let placeholderColor: Color
    let capturedAt: Date
    var reactions: [Reaction]
    
    init(
        id: UUID = UUID(),
        author: User,
        imageData: Data? = nil,
        placeholderColor: Color = .tymerDarkGray,
        capturedAt: Date = Date(),
        reactions: [Reaction] = []
    ) {
        self.id = id
        self.author = author
        self.imageData = imageData
        self.placeholderColor = placeholderColor
        self.capturedAt = capturedAt
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
    
    init(id: UUID = UUID(), author: User, type: ReactionType, createdAt: Date = Date()) {
        self.id = id
        self.author = author
        self.type = type
        self.createdAt = createdAt
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
struct TimeWindow {
    let start: Int // Heure de début (0-23)
    let end: Int   // Heure de fin (0-23)
    let label: String
    
    /// Fenêtre du matin (8h-9h)
    static let morning = TimeWindow(start: 8, end: 9, label: "Matin")
    
    /// Fenêtre du soir (19h-20h)
    static let evening = TimeWindow(start: 19, end: 20, label: "Soir")
    
    /// Toutes les fenêtres
    static let all: [TimeWindow] = [.morning, .evening]
    
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
    case onboarding
    case gate
    case feed
    case capture
    case circle
    case digest
    case messages
    case momentDetail(Moment)
    
    static func == (lhs: AppScreen, rhs: AppScreen) -> Bool {
        switch (lhs, rhs) {
        case (.splash, .splash),
             (.onboarding, .onboarding),
             (.gate, .gate),
             (.feed, .feed),
             (.capture, .capture),
             (.circle, .circle),
             (.digest, .digest),
             (.messages, .messages):
            return true
        case (.momentDetail(let lhsMoment), .momentDetail(let rhsMoment)):
            return lhsMoment.id == rhsMoment.id
        default:
            return false
        }
    }
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
            
            return Moment(
                author: user,
                placeholderColor: user.avatarColor.opacity(0.3),
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
            return Moment(
                author: User.currentUser,
                placeholderColor: colors[dayOffset].opacity(0.3),
                capturedAt: date
            )
        }
    }
}
