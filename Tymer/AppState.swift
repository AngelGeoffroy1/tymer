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
    
    // MARK: Weekly Digest
    var weeklyDigest: [Moment] = []
    
    // MARK: Debug Mode (pour tester sans restriction horaire)
    var debugModeEnabled: Bool = true
    
    // MARK: Audio Recording
    var audioRecorder: AVAudioRecorder?
    var isRecording: Bool = false
    
    private var timer: Timer?
    
    // MARK: - Initialization
    init() {
        loadLocalData()
        updateTimeWindowStatus()
        startTimer()
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
    
    // MARK: - Local Data Management
    
    func loadLocalData() {
        // Load circle from UserDefaults (mock pour le proto)
        if circle.isEmpty {
            circle = User.mockUsers
        }
        
        // Load moments
        if moments.isEmpty {
            moments = Moment.mockMoments()
        }
        
        // Load digest
        if weeklyDigest.isEmpty {
            weeklyDigest = Moment.mockWeeklyDigest()
        }
        
        // Check if posted today
        checkTodayPost()
    }
    
    private func checkTodayPost() {
        if let lastPostDate = UserDefaults.standard.object(forKey: StorageKey.lastPostDate) as? Date {
            let calendar = Calendar.current
            hasPostedToday = calendar.isDateInToday(lastPostDate)
            if !hasPostedToday {
                myTodayMoment = nil
            }
        }
    }
    
    func saveLocalData() {
        // Dans une vraie app on sauvegarderait en JSON/CoreData
        UserDefaults.standard.set(hasPostedToday, forKey: StorageKey.hasPosted)
    }
    
    // MARK: - Time Window Logic
    
    func updateTimeWindowStatus() {
        let now = Date()
        
        if debugModeEnabled {
            isWindowOpen = true
            currentWindow = .morning
            nextWindowCountdown = "Mode démo"
            return
        }
        
        for window in TimeWindow.all {
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
        
        var nextWindow: TimeWindow
        var nextDate: Date
        
        if currentHour < TimeWindow.morning.start {
            nextWindow = .morning
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = TimeWindow.morning.start
            components.minute = 0
            nextDate = calendar.date(from: components) ?? date
        } else if currentHour < TimeWindow.evening.start {
            nextWindow = .evening
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = TimeWindow.evening.start
            components.minute = 0
            nextDate = calendar.date(from: components) ?? date
        } else {
            nextWindow = .morning
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.day! += 1
            components.hour = TimeWindow.morning.start
            components.minute = 0
            nextDate = calendar.date(from: components) ?? date
        }
        
        let interval = nextDate.timeIntervalSince(date)
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(nextWindow.label) dans \(hours)h\(minutes)"
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
        // Sauvegarder l'image et récupérer son ID
        guard let imageId = ImageStorageManager.shared.saveImage(image) else {
            print("Erreur: Impossible de sauvegarder l'image")
            // Fallback: poster avec une couleur aléatoire
            let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .cyan]
            postMoment(placeholderColor: colors.randomElement() ?? .tymerDarkGray)
            return
        }

        // Nettoyer la description (nil si vide)
        let cleanDescription = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalDescription = (cleanDescription?.isEmpty ?? true) ? nil : cleanDescription

        // Créer le moment avec l'ID de l'image
        let newMoment = Moment(
            author: currentUser,
            imageName: imageId,
            placeholderColor: .tymerDarkGray,
            capturedAt: Date(),
            description: finalDescription
        )

        myTodayMoment = newMoment
        weeklyDigest.insert(newMoment, at: 0)
        hasPostedToday = true

        // Sauvegarder la date du post
        UserDefaults.standard.set(Date(), forKey: StorageKey.lastPostDate)
        saveLocalData()

        print("Moment posté avec image: \(imageId)")
    }
    
    // MARK: - Reaction Actions

    func addTextReaction(to moment: Moment, text: String) {
        guard !text.isEmpty else { return }

        let reaction = Reaction(
            author: currentUser,
            type: .text(text)
        )

        // Vérifier si c'est mon propre moment du jour
        if let myMoment = myTodayMoment, myMoment.id == moment.id {
            myTodayMoment?.reactions.append(reaction)
        }
        // Sinon chercher dans les moments des amis
        else if let index = moments.firstIndex(where: { $0.id == moment.id }) {
            moments[index].reactions.append(reaction)
        }
    }

    func addVoiceReaction(to moment: Moment, duration: TimeInterval) {
        let reaction = Reaction(
            author: currentUser,
            type: .voice(duration: min(duration, 3)) // Max 3 secondes
        )

        // Vérifier si c'est mon propre moment du jour
        if let myMoment = myTodayMoment, myMoment.id == moment.id {
            myTodayMoment?.reactions.append(reaction)
        }
        // Sinon chercher dans les moments des amis
        else if let index = moments.firstIndex(where: { $0.id == moment.id }) {
            moments[index].reactions.append(reaction)
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
