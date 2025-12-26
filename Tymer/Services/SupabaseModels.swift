//
//  SupabaseModels.swift
//  Tymer
//
//  Created by Claude on 26/12/2025.
//

import Foundation
import SwiftUI

// MARK: - Profile DTO

struct Profile: Codable, Identifiable, Equatable {
    let id: UUID
    let firstName: String
    let avatarColor: String
    let avatarUrl: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case avatarColor = "avatar_color"
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var displayColor: Color {
        Color.fromString(avatarColor)
    }

    var initials: String {
        String(firstName.prefix(1)).uppercased()
    }

    // Convert to local User model
    func toUser() -> User {
        User(id: id, firstName: firstName, avatarColor: displayColor)
    }
}

// MARK: - Moment DTO

struct MomentDTO: Codable, Identifiable {
    let id: UUID
    let authorId: UUID
    let imagePath: String?
    let description: String?
    let capturedAt: Date
    let createdAt: Date
    let updatedAt: Date

    // Nested relations
    var profiles: Profile?
    var reactions: [ReactionDTO]?

    enum CodingKeys: String, CodingKey {
        case id
        case authorId = "author_id"
        case imagePath = "image_path"
        case description
        case capturedAt = "captured_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case profiles
        case reactions
    }

    // Convert to local Moment model
    func toMoment() -> Moment {
        let author = profiles?.toUser() ?? User(firstName: "Inconnu")

        let localReactions = reactions?.map { $0.toReaction() } ?? []

        return Moment(
            id: id,
            author: author,
            imageName: imagePath,
            placeholderColor: author.avatarColor.opacity(0.4),
            capturedAt: capturedAt,
            description: description,
            reactions: localReactions
        )
    }
}

struct CreateMomentDTO: Codable {
    let authorId: UUID
    let imagePath: String?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case authorId = "author_id"
        case imagePath = "image_path"
        case description
    }
}

// MARK: - Reaction DTO

struct ReactionDTO: Codable, Identifiable {
    let id: UUID
    let momentId: UUID
    let authorId: UUID
    let reactionType: String
    let content: String?
    let duration: Float?
    let voicePath: String?
    let createdAt: Date

    var profiles: Profile?

    enum CodingKeys: String, CodingKey {
        case id
        case momentId = "moment_id"
        case authorId = "author_id"
        case reactionType = "reaction_type"
        case content
        case duration
        case voicePath = "voice_path"
        case createdAt = "created_at"
        case profiles
    }

    func toReaction() -> Reaction {
        let author = profiles?.toUser() ?? User(firstName: "Inconnu")

        let type: ReactionType
        if reactionType == "voice", let dur = duration {
            type = .voice(duration: TimeInterval(dur))
        } else {
            type = .text(content ?? "")
        }

        return Reaction(
            id: id,
            author: author,
            type: type,
            createdAt: createdAt
        )
    }
}

struct CreateReactionDTO: Codable {
    let momentId: UUID
    let authorId: UUID
    let reactionType: String
    let content: String?
    let duration: Float?
    var voicePath: String?

    enum CodingKeys: String, CodingKey {
        case momentId = "moment_id"
        case authorId = "author_id"
        case reactionType = "reaction_type"
        case content
        case duration
        case voicePath = "voice_path"
    }
}

// MARK: - Friendship DTO

struct FriendshipDTO: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let friendId: UUID
    let status: String
    let createdAt: Date

    var user: Profile?
    var friend: Profile?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case friendId = "friend_id"
        case status
        case createdAt = "created_at"
        case user
        case friend
    }
}

struct CreateFriendshipDTO: Codable {
    let userId: UUID
    let friendId: UUID

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case friendId = "friend_id"
    }
}

// MARK: - Posting Date DTO

struct PostingDateDTO: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let momentId: UUID
    let postedDate: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case momentId = "moment_id"
        case postedDate = "posted_date"
        case createdAt = "created_at"
    }
}

struct CreatePostingDateDTO: Codable {
    let userId: UUID
    let momentId: UUID

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case momentId = "moment_id"
    }
}

// MARK: - Color Extension

extension Color {
    static func fromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "cyan": return .cyan
        case "yellow": return .yellow
        case "mint": return .mint
        case "indigo": return .indigo
        case "teal": return .teal
        case "brown": return .brown
        case "white": return .white
        case "gray": return .gray
        default: return .blue
        }
    }

    var colorName: String {
        switch self {
        case .red: return "red"
        case .blue: return "blue"
        case .green: return "green"
        case .orange: return "orange"
        case .purple: return "purple"
        case .pink: return "pink"
        case .cyan: return "cyan"
        case .yellow: return "yellow"
        case .mint: return "mint"
        case .indigo: return "indigo"
        case .teal: return "teal"
        case .brown: return "brown"
        case .white: return "white"
        case .gray: return "gray"
        default: return "blue"
        }
    }
}
