//
//  SupabaseManager.swift
//  Tymer
//
//  Created by Claude on 26/12/2025.
//

import Foundation
import Combine
import Supabase

@MainActor
final class SupabaseManager: ObservableObject {

    static let shared = SupabaseManager()

    let client: SupabaseClient

    @Published var currentSession: Session?
    @Published var currentProfile: Profile?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://rqxouyoxrxzhtlzfexhw.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJxeG91eW94cnh6aHRsemZleGh3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY3MTgyMDMsImV4cCI6MjA4MjI5NDIwM30.T8OJ2D-ccTaM13E8DeHpIN8phEcgR5DVrm3T4X7A4yg"
        )

        Task {
            await checkSession()
        }
    }

    // MARK: - Auth State

    var isAuthenticated: Bool {
        currentSession != nil
    }

    var userId: UUID? {
        currentSession?.user.id
    }

    // MARK: - Session Management

    func checkSession() async {
        do {
            currentSession = try await client.auth.session
            if currentSession != nil {
                await fetchCurrentProfile()
            }
        } catch {
            currentSession = nil
            currentProfile = nil
        }
    }

    // MARK: - Auth Methods

    func signUp(email: String, password: String, firstName: String, avatarColor: String) async throws {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password,
                data: [
                    "first_name": .string(firstName),
                    "avatar_color": .string(avatarColor)
                ]
            )

            currentSession = response.session

            if currentSession != nil {
                await fetchCurrentProfile()
            }
        } catch {
            errorMessage = parseAuthError(error)
            throw error
        }
    }

    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )

            currentSession = session
            await fetchCurrentProfile()
        } catch {
            errorMessage = parseAuthError(error)
            throw error
        }
    }

    func signOut() async throws {
        try await client.auth.signOut()
        currentSession = nil
        currentProfile = nil
    }

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    private func parseAuthError(_ error: Error) -> String {
        let errorString = error.localizedDescription.lowercased()

        if errorString.contains("invalid login credentials") {
            return "Email ou mot de passe incorrect"
        } else if errorString.contains("email not confirmed") {
            return "Veuillez confirmer votre email"
        } else if errorString.contains("user already registered") {
            return "Cet email est déjà utilisé"
        } else if errorString.contains("password") && errorString.contains("weak") {
            return "Le mot de passe doit contenir au moins 6 caractères"
        } else if errorString.contains("invalid email") {
            return "Email invalide"
        }

        return "Une erreur est survenue. Réessayez."
    }

    // MARK: - Profile

    func fetchCurrentProfile() async {
        guard let userId = userId else { return }

        do {
            let profile: Profile = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value

            currentProfile = profile
        } catch {
            print("Error fetching profile: \(error)")
        }
    }

    func updateProfile(firstName: String? = nil, avatarColor: String? = nil) async throws {
        guard let userId = userId else { return }

        var updates: [String: AnyJSON] = [:]
        if let firstName = firstName { updates["first_name"] = .string(firstName) }
        if let avatarColor = avatarColor { updates["avatar_color"] = .string(avatarColor) }

        try await client
            .from("profiles")
            .update(updates)
            .eq("id", value: userId.uuidString)
            .execute()

        await fetchCurrentProfile()
    }

    // MARK: - Moments

    func fetchFriendsMoments() async throws -> [MomentDTO] {
        guard let userId = userId else { return [] }

        // Calculate start of today (midnight)
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let dateFormatter = ISO8601DateFormatter()
        let todayString = dateFormatter.string(from: startOfToday)

        // Fetch moments from friends only, captured today
        let moments: [MomentDTO] = try await client
            .from("moments")
            .select("*, profiles!author_id(*), reactions(*, profiles!author_id(*))")
            .neq("author_id", value: userId.uuidString)
            .gte("captured_at", value: todayString)
            .order("captured_at", ascending: false)
            .execute()
            .value

        return moments
    }

    func fetchMyMoments(limit: Int = 7) async throws -> [MomentDTO] {
        guard let userId = userId else { return [] }

        let moments: [MomentDTO] = try await client
            .from("moments")
            .select("*, profiles!author_id(*), reactions(*, profiles!author_id(*))")
            .eq("author_id", value: userId.uuidString)
            .order("captured_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return moments
    }

    func hasPostedToday() async throws -> Bool {
        guard let userId = userId else { return false }

        // Check if user has a moment captured today
        let moments = try await fetchMyMoments(limit: 1)
        guard let lastMoment = moments.first else { return false }

        return Calendar.current.isDateInToday(lastMoment.capturedAt)
    }

    func createMoment(imagePath: String?, description: String?) async throws -> MomentDTO {
        guard let userId = userId else {
            throw NSError(domain: "SupabaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non authentifié"])
        }

        let newMoment = CreateMomentDTO(
            authorId: userId,
            imagePath: imagePath,
            description: description
        )

        let moment: MomentDTO = try await client
            .from("moments")
            .insert(newMoment)
            .select("*, profiles!author_id(*)")
            .single()
            .execute()
            .value

        return moment
    }

    func deleteMoment(_ momentId: UUID, imagePath: String?) async throws {
        // Delete image from storage if exists
        if let imagePath = imagePath {
            _ = try? await client.storage
                .from("moments")
                .remove(paths: [imagePath])
        }

        // Delete the moment from database
        try await client
            .from("moments")
            .delete()
            .eq("id", value: momentId.uuidString)
            .execute()
    }

    // MARK: - Reactions

    func addTextReaction(to momentId: UUID, text: String) async throws {
        guard let userId = userId else { return }

        let reaction = CreateReactionDTO(
            momentId: momentId,
            authorId: userId,
            reactionType: "text",
            content: text,
            duration: nil
        )

        try await client
            .from("reactions")
            .insert(reaction)
            .execute()
    }

    func addVoiceReaction(to momentId: UUID, duration: Double, voicePath: String, waveformData: [Float]? = nil) async throws {
        guard let userId = userId else { return }

        let reaction = CreateReactionDTO(
            momentId: momentId,
            authorId: userId,
            reactionType: "voice",
            content: nil,
            duration: Float(duration),
            voicePath: voicePath,
            waveformData: waveformData
        )

        try await client
            .from("reactions")
            .insert(reaction)
            .execute()
    }

    // MARK: - Friendships

    func fetchFriends() async throws -> [Profile] {
        guard let userId = userId else { return [] }

        // Get all accepted friendships where I'm either user or friend
        let friendships: [FriendshipDTO] = try await client
            .from("friendships")
            .select("*, user:profiles!user_id(*), friend:profiles!friend_id(*)")
            .or("user_id.eq.\(userId.uuidString),friend_id.eq.\(userId.uuidString)")
            .eq("status", value: "accepted")
            .execute()
            .value

        // Extract the friend profiles
        var friends: [Profile] = []
        for friendship in friendships {
            if friendship.userId == userId {
                if let friend = friendship.friend {
                    friends.append(friend)
                }
            } else {
                if let user = friendship.user {
                    friends.append(user)
                }
            }
        }

        return friends
    }

    func sendFriendRequest(to friendId: UUID) async throws {
        guard let userId = userId else { return }

        let friendship = CreateFriendshipDTO(userId: userId, friendId: friendId)

        try await client
            .from("friendships")
            .insert(friendship)
            .execute()
    }

    func acceptFriendRequest(friendshipId: UUID) async throws {
        try await client
            .from("friendships")
            .update(["status": "accepted"])
            .eq("id", value: friendshipId.uuidString)
            .execute()
    }

    func removeFriend(friendshipId: UUID) async throws {
        try await client
            .from("friendships")
            .delete()
            .eq("id", value: friendshipId.uuidString)
            .execute()
    }

    // MARK: - Invitations

    /// Generate a unique invitation code
    private func generateInviteCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<8).map { _ in characters.randomElement()! })
    }

    /// Create a new invitation and return the invite code
    func createInvitation() async throws -> String {
        guard let userId = userId else {
            throw NSError(domain: "SupabaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non authentifié"])
        }

        let code = generateInviteCode()
        let invitation = CreateInvitationDTO(creatorId: userId, code: code)

        try await client
            .from("invitations")
            .insert(invitation)
            .execute()

        return code
    }

    /// Fetch the current user's active invitation (creates one if none exists)
    func getOrCreateInvitation() async throws -> String {
        guard let userId = userId else {
            throw NSError(domain: "SupabaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non authentifié"])
        }

        // Check for existing valid invitation
        let invitations: [InvitationDTO] = try await client
            .from("invitations")
            .select()
            .eq("creator_id", value: userId.uuidString)
            .eq("is_used", value: false)
            .gte("expires_at", value: ISO8601DateFormatter().string(from: Date()))
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value

        if let existingInvitation = invitations.first {
            return existingInvitation.code
        }

        // Create new invitation if none exists
        return try await createInvitation()
    }

    /// Validate an invitation code and return the invitation details
    func validateInvitation(code: String) async throws -> InvitationDTO? {
        let invitations: [InvitationDTO] = try await client
            .from("invitations")
            .select("*, creator:profiles!creator_id(*)")
            .eq("code", value: code)
            .eq("is_used", value: false)
            .limit(1)
            .execute()
            .value

        guard let invitation = invitations.first else { return nil }

        // Check if expired
        if let expiresAt = invitation.expiresAt, expiresAt < Date() {
            return nil
        }

        return invitation
    }

    /// Accept an invitation - marks it as used and creates friendship
    func acceptInvitation(code: String) async throws -> Profile? {
        guard let userId = userId else {
            throw NSError(domain: "SupabaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non authentifié"])
        }

        // Validate invitation
        guard let invitation = try await validateInvitation(code: code) else {
            throw NSError(domain: "SupabaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Invitation invalide ou expirée"])
        }

        // Can't accept own invitation
        if invitation.creatorId == userId {
            throw NSError(domain: "SupabaseManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Tu ne peux pas accepter ta propre invitation"])
        }

        // Check if already friends
        let existingFriendships: [FriendshipDTO] = try await client
            .from("friendships")
            .select()
            .or("and(user_id.eq.\(userId.uuidString),friend_id.eq.\(invitation.creatorId.uuidString)),and(user_id.eq.\(invitation.creatorId.uuidString),friend_id.eq.\(userId.uuidString))")
            .execute()
            .value

        if !existingFriendships.isEmpty {
            throw NSError(domain: "SupabaseManager", code: 409, userInfo: [NSLocalizedDescriptionKey: "Vous êtes déjà amis"])
        }

        // Mark invitation as used
        try await client
            .from("invitations")
            .update([
                "is_used": AnyJSON.bool(true),
                "used_by": AnyJSON.string(userId.uuidString),
                "used_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
            ])
            .eq("id", value: invitation.id.uuidString)
            .execute()

        // Create friendship (directly accepted)
        let friendship = CreateFriendshipDTO(userId: invitation.creatorId, friendId: userId)
        try await client
            .from("friendships")
            .insert(friendship)
            .execute()

        // Accept the friendship immediately
        try await client
            .from("friendships")
            .update(["status": "accepted"])
            .eq("user_id", value: invitation.creatorId.uuidString)
            .eq("friend_id", value: userId.uuidString)
            .execute()

        return invitation.creator
    }

    // MARK: - Storage

    func uploadMomentImage(_ imageData: Data) async throws -> String {
        guard let userId = userId else {
            throw NSError(domain: "SupabaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non authentifié"])
        }

        // UUID must be lowercase to match auth.uid() in RLS policies
        let fileName = "\(userId.uuidString.lowercased())/\(UUID().uuidString.lowercased()).jpg"

        try await client.storage
            .from("moments")
            .upload(fileName, data: imageData, options: FileOptions(contentType: "image/jpeg"))

        return fileName
    }

    func getMomentImageURL(_ path: String) -> URL? {
        try? client.storage
            .from("moments")
            .getPublicURL(path: path)
    }

    func uploadVoiceReaction(_ audioData: Data) async throws -> String {
        guard let userId = userId else {
            throw NSError(domain: "SupabaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non authentifié"])
        }

        // UUID must be lowercase to match auth.uid() in RLS policies
        let fileName = "\(userId.uuidString.lowercased())/\(UUID().uuidString.lowercased()).m4a"

        try await client.storage
            .from("voice-reactions")
            .upload(fileName, data: audioData, options: FileOptions(contentType: "audio/m4a"))

        return fileName
    }

    func getVoiceReactionURL(_ path: String) -> URL? {
        try? client.storage
            .from("voice-reactions")
            .getPublicURL(path: path)
    }

    // MARK: - Windows

    func fetchWindows() async throws -> [WindowDTO] {
        let windows: [WindowDTO] = try await client
            .from("windows")
            .select()
            .order("start_hour", ascending: true)
            .execute()
            .value

        return windows
    }

    // MARK: - Avatar

    func uploadAvatar(_ imageData: Data) async throws -> String {
        guard let userId = userId else {
            throw NSError(domain: "SupabaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non authentifié"])
        }

        // UUID must be lowercase to match auth.uid() in RLS policies
        let fileName = "\(userId.uuidString.lowercased())/avatar.jpg"

        // Try to remove existing avatar first (ignore errors)
        _ = try? await client.storage
            .from("avatars")
            .remove(paths: [fileName])

        try await client.storage
            .from("avatars")
            .upload(fileName, data: imageData, options: FileOptions(contentType: "image/jpeg", upsert: true))

        // Get public URL and update profile
        let publicURL = try client.storage
            .from("avatars")
            .getPublicURL(path: fileName)

        try await client
            .from("profiles")
            .update(["avatar_url": publicURL.absoluteString])
            .eq("id", value: userId.uuidString)
            .execute()

        await fetchCurrentProfile()

        return publicURL.absoluteString
    }

    func getAvatarURL() -> URL? {
        guard let avatarUrl = currentProfile?.avatarUrl else { return nil }
        return URL(string: avatarUrl)
    }
}
