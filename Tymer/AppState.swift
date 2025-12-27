//
//  AppState.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI
import Combine
import AVFoundation

// MARK: - App State
@Observable
final class AppState {

    // MARK: Navigation
    var currentScreen: AppScreen = .splash
    var navigationPath: [AppScreen] = []

    // MARK: User State
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }

    var currentUser: User = .currentUser
    var circle: [User] = []

    // MARK: Feed State
    var moments: [Moment] = []
    var hasPostedToday: Bool = false
    var currentMomentIndex: Int = 0
    var myTodayMoment: Moment?

    // MARK: Time Window State
    var isWindowOpen: Bool = false
    var currentWindow: TimeWindow?
    var nextWindowCountdown: String = ""
    var timeWindows: [TimeWindow] = [] // Loaded from Supabase

    // MARK: Weekly Digest
    var weeklyDigest: [Moment] = []

    // MARK: Debug Mode (pour tester sans restriction horaire)
    var debugModeEnabled: Bool = false

    // MARK: Audio Recording
    var audioRecorder: AVAudioRecorder?
    var isRecording: Bool = false

    // MARK: Loading States
    var isLoadingMoments: Bool = false
    var isLoadingFriends: Bool = false

    private var timer: Timer?
    private let supabase = SupabaseManager.shared

    // MARK: - Initialization
    init() {
        updateTimeWindowStatus()
        startTimer()

        // Load data if authenticated
        Task { @MainActor in
            await loadData()
        }
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Local Storage Keys
    private enum StorageKey {
        static let circle = "tymer_circle"
        static let moments = "tymer_moments"
        static let myMoment = "tymer_my_moment"
        static let hasPosted = "tymer_has_posted"
        static let lastPostDate = "tymer_last_post_date"
    }

    // MARK: - Data Loading (Supabase)

    @MainActor
    func loadData() async {
        // Always load windows first (even if not authenticated)
        await loadTimeWindows()

        guard supabase.isAuthenticated else {
            // No mock data - show empty state when not authenticated
            return
        }

        // Update current user from profile
        if let profile = supabase.currentProfile {
            currentUser = profile.toUser()
        }

        // Load data in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadFriends() }
            group.addTask { await self.loadFriendsMoments() }
            group.addTask { await self.loadMyMoments() }
            group.addTask { await self.checkTodayPostFromServer() }
        }
    }

    /// Check if error is a cancellation (should be ignored during refresh)
    private func isCancellationError(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
    }

    @MainActor
    private func loadTimeWindows() async {
        do {
            let windowDTOs = try await supabase.fetchWindows()
            timeWindows = windowDTOs.map { $0.toTimeWindow() }
            updateTimeWindowStatus()
        } catch {
            // Ignore cancellation errors, preserve existing data
            guard !isCancellationError(error) else { return }
            print("Error loading time windows: \(error)")
            // Use default windows as fallback only if we have none
            if timeWindows.isEmpty {
                timeWindows = TimeWindow.defaultWindows
            }
            updateTimeWindowStatus()
        }
    }

    @MainActor
    private func loadFriends() async {
        isLoadingFriends = true
        defer { isLoadingFriends = false }

        do {
            let friends = try await supabase.fetchFriends()
            circle = friends.map { $0.toUser() }
        } catch {
            // Ignore cancellation errors, preserve existing data
            guard !isCancellationError(error) else { return }
            print("Error loading friends: \(error)")
        }
    }

    @MainActor
    private func loadFriendsMoments() async {
        isLoadingMoments = true
        defer { isLoadingMoments = false }

        do {
            let momentDTOs = try await supabase.fetchFriendsMoments()
            moments = momentDTOs.map { $0.toMoment() }
        } catch {
            // Ignore cancellation errors, preserve existing data
            guard !isCancellationError(error) else { return }
            print("Error loading moments: \(error)")
        }
    }

    @MainActor
    private func loadMyMoments() async {
        do {
            let myMomentDTOs = try await supabase.fetchMyMoments(limit: 7)
            weeklyDigest = myMomentDTOs.map { $0.toMoment() }

            // Check if today's moment exists
            let calendar = Calendar.current
            if let todayMoment = myMomentDTOs.first(where: { calendar.isDateInToday($0.capturedAt) }) {
                myTodayMoment = todayMoment.toMoment()
            }
        } catch {
            // Ignore cancellation errors, preserve existing data
            guard !isCancellationError(error) else { return }
            print("Error loading my moments: \(error)")
        }
    }

    @MainActor
    private func checkTodayPostFromServer() async {
        do {
            hasPostedToday = try await supabase.hasPostedToday()
        } catch {
            // Ignore cancellation errors, preserve existing data
            guard !isCancellationError(error) else { return }
            print("Error checking today post: \(error)")
            // Fallback to local check only for real errors
            checkTodayPostLocal()
        }
    }

    private func checkTodayPostLocal() {
        if let lastPostDate = UserDefaults.standard.object(forKey: StorageKey.lastPostDate) as? Date {
            let calendar = Calendar.current
            hasPostedToday = calendar.isDateInToday(lastPostDate)
            if !hasPostedToday {
                myTodayMoment = nil
            }
        }
    }

    func saveLocalData() {
        UserDefaults.standard.set(hasPostedToday, forKey: StorageKey.hasPosted)
    }

    // Legacy method for compatibility
    func loadLocalData() {
        Task { @MainActor in
            await loadData()
        }
    }
    
    // MARK: - Time Window Logic

    func updateTimeWindowStatus() {
        let now = Date()

        // Use loaded windows or defaults
        let windows = timeWindows.isEmpty ? TimeWindow.defaultWindows : timeWindows

        if debugModeEnabled {
            isWindowOpen = true
            currentWindow = windows.first ?? .morning
            nextWindowCountdown = "Mode démo"
            return
        }

        for window in windows {
            if window.isOpen(at: now) {
                isWindowOpen = true
                currentWindow = window
                if let remaining = window.remainingTime(at: now) {
                    let minutes = Int(remaining / 60)
                    nextWindowCountdown = "Ferme dans \(minutes)min"
                }
                return
            }
        }

        isWindowOpen = false
        currentWindow = nil
        nextWindowCountdown = calculateNextWindowCountdown(from: now)
    }
    
    private func calculateNextWindowCountdown(from date: Date) -> String {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: date)

        // Use loaded windows or defaults
        let windows = timeWindows.isEmpty ? TimeWindow.defaultWindows : timeWindows
        let sortedWindows = windows.sorted { $0.start < $1.start }

        guard !sortedWindows.isEmpty else {
            return "Aucune fenêtre"
        }

        // Find the next window
        var nextWindow: TimeWindow?
        var nextDate: Date?

        // Check for windows later today
        for window in sortedWindows {
            if currentHour < window.start {
                nextWindow = window
                var components = calendar.dateComponents([.year, .month, .day], from: date)
                components.hour = window.start
                components.minute = 0
                nextDate = calendar.date(from: components)
                break
            }
        }

        // If no window found today, use first window tomorrow
        if nextWindow == nil {
            nextWindow = sortedWindows.first
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.day! += 1
            components.hour = nextWindow!.start
            components.minute = 0
            nextDate = calendar.date(from: components)
        }

        guard let window = nextWindow, let targetDate = nextDate else {
            return "Aucune fenêtre"
        }

        let interval = targetDate.timeIntervalSince(date)
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return "\(window.label) dans \(hours)h\(minutes)"
        } else {
            return "Dans \(minutes)min"
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateTimeWindowStatus()
        }
    }
    
    // MARK: - Navigation
    
    func navigate(to screen: AppScreen) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentScreen = screen
        }
    }
    
    func goBack() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if !navigationPath.isEmpty {
                navigationPath.removeLast()
            } else {
                currentScreen = .gate
            }
        }
    }
    
    // MARK: - Circle Actions
    
    var circleCount: Int { circle.count }
    let circleLimit: Int = 25
    var canAddFriend: Bool { circleCount < circleLimit }
    
    func removeFriend(_ user: User) {
        circle.removeAll { $0.id == user.id }
        // Supprimer aussi ses moments du feed
        moments.removeAll { $0.author.id == user.id }
    }
    
    func addFriend(_ user: User) {
        guard canAddFriend else { return }
        circle.append(user)
    }
    
    // MARK: - Post Actions

    func postMoment(imageName: String? = nil, placeholderColor: Color = .tymerDarkGray) {
        let newMoment = Moment(
            author: currentUser,
            imageName: imageName,
            placeholderColor: placeholderColor,
            capturedAt: Date()
        )

        myTodayMoment = newMoment
        weeklyDigest.insert(newMoment, at: 0)
        hasPostedToday = true

        // Sauvegarder la date du post
        UserDefaults.standard.set(Date(), forKey: StorageKey.lastPostDate)
        saveLocalData()
    }

    /// Poste un moment avec une image capturée et une description optionnelle
    func postMomentWithImage(_ image: UIImage, description: String? = nil) {
        Task { @MainActor in
            await postMomentWithImageAsync(image, description: description)
        }
    }

    @MainActor
    private func postMomentWithImageAsync(_ image: UIImage, description: String?) async {
        // Nettoyer la description (nil si vide)
        let cleanDescription = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalDescription = (cleanDescription?.isEmpty ?? true) ? nil : cleanDescription

        // Try to upload to Supabase if authenticated
        if supabase.isAuthenticated {
            do {
                // Compress image
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    print("Error: Cannot compress image")
                    fallbackPostMoment(image, description: finalDescription)
                    return
                }

                // Upload to Supabase Storage
                let imagePath = try await supabase.uploadMomentImage(imageData)

                // Create moment in database
                let momentDTO = try await supabase.createMoment(imagePath: imagePath, description: finalDescription)
                let newMoment = momentDTO.toMoment()

                myTodayMoment = newMoment
                weeklyDigest.insert(newMoment, at: 0)
                hasPostedToday = true

                print("Moment posted to Supabase: \(momentDTO.id)")
                return

            } catch {
                print("Error posting to Supabase: \(error)")
                // Fallback to local storage
            }
        }

        // Fallback: save locally
        fallbackPostMoment(image, description: finalDescription)
    }

    private func fallbackPostMoment(_ image: UIImage, description: String?) {
        // Sauvegarder l'image localement et récupérer son ID
        guard let imageId = ImageStorageManager.shared.saveImage(image) else {
            print("Erreur: Impossible de sauvegarder l'image")
            let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .cyan]
            postMoment(placeholderColor: colors.randomElement() ?? .tymerDarkGray)
            return
        }

        let newMoment = Moment(
            author: currentUser,
            imageName: imageId,
            placeholderColor: .tymerDarkGray,
            capturedAt: Date(),
            description: description
        )

        myTodayMoment = newMoment
        weeklyDigest.insert(newMoment, at: 0)
        hasPostedToday = true

        UserDefaults.standard.set(Date(), forKey: StorageKey.lastPostDate)
        saveLocalData()

        print("Moment posté localement: \(imageId)")
    }
    
    // MARK: - Reaction Actions

    func addTextReaction(to moment: Moment, text: String) {
        guard !text.isEmpty else { return }

        let reaction = Reaction(
            author: currentUser,
            type: .text(text)
        )

        // Update local state immediately
        if let myMoment = myTodayMoment, myMoment.id == moment.id {
            myTodayMoment?.reactions.append(reaction)
        } else if let index = moments.firstIndex(where: { $0.id == moment.id }) {
            moments[index].reactions.append(reaction)
        }

        // Sync with Supabase
        if supabase.isAuthenticated {
            Task {
                do {
                    try await supabase.addTextReaction(to: moment.id, text: text)
                } catch {
                    print("Error adding text reaction: \(error)")
                }
            }
        }
    }

    func addVoiceReaction(to moment: Moment, duration: TimeInterval, audioData: Data? = nil) {
        let reaction = Reaction(
            author: currentUser,
            type: .voice(duration: min(duration, 3))
        )

        // Update local state immediately
        if let myMoment = myTodayMoment, myMoment.id == moment.id {
            myTodayMoment?.reactions.append(reaction)
        } else if let index = moments.firstIndex(where: { $0.id == moment.id }) {
            moments[index].reactions.append(reaction)
        }

        // Sync with Supabase
        if supabase.isAuthenticated, let data = audioData {
            Task {
                do {
                    let voicePath = try await supabase.uploadVoiceReaction(data)
                    try await supabase.addVoiceReaction(to: moment.id, duration: min(duration, 3), voicePath: voicePath)
                } catch {
                    print("Error adding voice reaction: \(error)")
                }
            }
        }
    }
    
    // MARK: - Audio Recording
    
    func startVoiceRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("voice_reaction_\(UUID().uuidString).m4a")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
            
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopVoiceRecording() -> TimeInterval {
        guard let recorder = audioRecorder, isRecording else { return 0 }
        
        let duration = recorder.currentTime
        recorder.stop()
        isRecording = false
        audioRecorder = nil
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        return min(duration, 3) // Max 3 secondes
    }
}
