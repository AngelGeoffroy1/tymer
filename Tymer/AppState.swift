//
//  AppState.swift
//  Tymer
//
//  Created by Angel Geoffroy on 24/12/2025.
//

import SwiftUI
import Combine

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
    var circle: [User] = User.mockUsers
    
    // MARK: Feed State
    var moments: [Moment] = Moment.mockMoments()
    var hasPostedToday: Bool = false
    var currentMomentIndex: Int = 0
    
    // MARK: Time Window State
    var isWindowOpen: Bool = false
    var currentWindow: TimeWindow?
    var nextWindowCountdown: String = ""
    
    // MARK: Weekly Digest
    var weeklyDigest: [Moment] = Moment.mockWeeklyDigest()
    
    // MARK: Debug Mode (pour tester sans restriction horaire)
    var debugModeEnabled: Bool = true
    
    private var timer: Timer?
    
    // MARK: - Initialization
    init() {
        updateTimeWindowStatus()
        startTimer()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Time Window Logic
    
    /// Met à jour le statut de la fenêtre horaire
    func updateTimeWindowStatus() {
        let now = Date()
        
        // En mode debug, la fenêtre est toujours ouverte
        if debugModeEnabled {
            isWindowOpen = true
            currentWindow = .morning
            nextWindowCountdown = "Mode démo"
            return
        }
        
        // Vérifie si une fenêtre est ouverte
        for window in TimeWindow.all {
            if window.isOpen(at: now) {
                isWindowOpen = true
                currentWindow = window
                if let remaining = window.remainingTime(at: now) {
                    let minutes = Int(remaining / 60)
                    nextWindowCountdown = "Fermeture dans \(minutes) min"
                }
                return
            }
        }
        
        // Aucune fenêtre ouverte
        isWindowOpen = false
        currentWindow = nil
        nextWindowCountdown = calculateNextWindowCountdown(from: now)
    }
    
    /// Calcule le temps jusqu'à la prochaine fenêtre
    private func calculateNextWindowCountdown(from date: Date) -> String {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: date)
        
        var nextWindow: TimeWindow
        var nextDate: Date
        
        if currentHour < TimeWindow.morning.start {
            // Avant 8h → prochaine fenêtre = matin
            nextWindow = .morning
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = TimeWindow.morning.start
            components.minute = 0
            nextDate = calendar.date(from: components) ?? date
        } else if currentHour < TimeWindow.evening.start {
            // Entre 9h et 19h → prochaine fenêtre = soir
            nextWindow = .evening
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = TimeWindow.evening.start
            components.minute = 0
            nextDate = calendar.date(from: components) ?? date
        } else {
            // Après 20h → prochaine fenêtre = matin demain
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
            return "Prochaine fenêtre (\(nextWindow.label)) dans \(hours)h\(minutes)"
        } else {
            return "Prochaine fenêtre dans \(minutes) min"
        }
    }
    
    /// Démarre le timer pour mettre à jour le countdown
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
    
    // MARK: - Feed Actions
    
    /// Passe au moment suivant dans le feed
    func nextMoment() -> Bool {
        if currentMomentIndex < moments.count - 1 {
            currentMomentIndex += 1
            return true
        }
        return false // Fin du feed
    }
    
    /// Revient au moment précédent
    func previousMoment() -> Bool {
        if currentMomentIndex > 0 {
            currentMomentIndex -= 1
            return true
        }
        return false
    }
    
    /// Réinitialise le feed
    func resetFeed() {
        currentMomentIndex = 0
    }
    
    // MARK: - Circle Actions
    
    /// Nombre d'amis dans le cercle
    var circleCount: Int { circle.count }
    
    /// Limite du cercle
    let circleLimit: Int = 25
    
    /// Peut encore ajouter des amis
    var canAddFriend: Bool { circleCount < circleLimit }
    
    // MARK: - Post Actions
    
    /// Simule la publication d'un moment
    func postMoment(placeholderColor: Color = .tymerDarkGray) {
        let newMoment = Moment(
            author: currentUser,
            placeholderColor: placeholderColor
        )
        moments.insert(newMoment, at: 0)
        hasPostedToday = true
    }
}
