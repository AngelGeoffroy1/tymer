//
//  NotificationManager.swift
//  Tymer
//
//  Created by Angel Geoffroy on 03/01/2026.
//

import Foundation
import UserNotifications
import UIKit
import Combine

// MARK: - Notification Manager
/// Manages local push notifications for time window openings
final class NotificationManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    static let shared = NotificationManager()
    
    // MARK: - Published Properties
    @Published private(set) var isAuthorized: Bool = false
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    private let windowNotificationCategory = "WINDOW_OPEN"
    private let notificationIdPrefix = "tymer_window_"
    
    // MARK: - Initialization
    override private init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
        setupNotificationCategories()
    }
    
    // MARK: - Authorization
    
    /// Check current authorization status
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Request notification permissions
    /// - Returns: Whether authorization was granted
    @MainActor
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            authorizationStatus = granted ? .authorized : .denied
            
            if granted {
                print("📬 Notification permission granted")
            } else {
                print("📬 Notification permission denied")
            }
            
            return granted
        } catch {
            print("📬 Error requesting notification permission: \(error)")
            return false
        }
    }
    
    /// Open system settings for notifications
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Notification Categories
    
    /// Setup notification categories with actions
    private func setupNotificationCategories() {
        // Action to open the app and go to camera
        let captureAction = UNNotificationAction(
            identifier: "CAPTURE_ACTION",
            title: "📸 Capturer mon moment",
            options: [.foreground]
        )
        
        // Action to dismiss
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Plus tard",
            options: []
        )
        
        // Category for window open notifications
        let windowCategory = UNNotificationCategory(
            identifier: windowNotificationCategory,
            actions: [captureAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        notificationCenter.setNotificationCategories([windowCategory])
    }
    
    // MARK: - Schedule Notifications
    
    /// Schedule notifications for all time windows
    /// - Parameter windows: Array of TimeWindow to schedule notifications for
    func scheduleWindowNotifications(_ windows: [TimeWindow]) {
        // Cancel existing window notifications first
        cancelAllWindowNotifications()
        
        guard isAuthorized else {
            print("📬 Cannot schedule notifications: not authorized")
            return
        }
        
        for window in windows {
            scheduleNotification(for: window)
        }
        
        print("📬 Scheduled notifications for \(windows.count) windows")
    }
    
    /// Schedule a notification for a specific time window
    /// - Parameter window: The time window to schedule notification for
    private func scheduleNotification(for window: TimeWindow) {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "🔓 Fenêtre ouverte !"
        content.body = getNotificationBody(for: window)
        content.sound = .default
        content.categoryIdentifier = windowNotificationCategory
        content.badge = 1
        
        // Add custom data
        content.userInfo = [
            "windowLabel": window.label,
            "windowStart": window.start,
            "windowEnd": window.end
        ]
        
        // Create trigger for the window start time (daily repeating)
        var dateComponents = DateComponents()
        dateComponents.hour = window.start
        dateComponents.minute = 0
        dateComponents.second = 0
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        // Create request
        let identifier = "\(notificationIdPrefix)\(window.start)_\(window.end)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        notificationCenter.add(request) { error in
            if let error = error {
                print("📬 Error scheduling notification: \(error)")
            } else {
                print("📬 Scheduled notification for \(window.label) at \(window.start)h")
            }
        }
    }
    
    /// Get notification body text based on window type
    private func getNotificationBody(for window: TimeWindow) -> String {
        let messages: [String] = [
            "C'est le moment de capturer ton instant ! Tu as 1 heure.",
            "Ta fenêtre \(window.label.lowercased()) est ouverte ! 📸",
            "Montre à ton cercle ce que tu fais en ce moment !",
            "Tes amis t'attendent ! Capture ton moment.",
            "1 heure pour partager avec ton cercle. Go ! 🚀"
        ]
        // Use window start hour to consistently pick a message
        return messages[window.start % messages.count]
    }
    
    // MARK: - Cancel Notifications
    
    /// Cancel all scheduled window notifications
    func cancelAllWindowNotifications() {
        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            guard let self = self else { return }
            
            let windowIds = requests
                .filter { $0.identifier.hasPrefix(self.notificationIdPrefix) }
                .map { $0.identifier }
            
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: windowIds)
            print("📬 Cancelled \(windowIds.count) window notifications")
        }
    }
    
    /// Cancel all notifications (pending and delivered)
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        print("📬 Cancelled all notifications")
    }
    
    // MARK: - Badge Management
    
    /// Clear the app badge count
    @MainActor
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
    
    // MARK: - Debug Helpers
    
    /// Send a test notification (for debugging)
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🔓 Fenêtre ouverte !"
        content.body = "C'est le moment de capturer ton instant !"
        content.sound = .default
        content.categoryIdentifier = windowNotificationCategory
        
        // Trigger in 5 seconds
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "test_notification_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("📬 Error sending test notification: \(error)")
            } else {
                print("📬 Test notification scheduled for 5 seconds")
            }
        }
    }
    
    /// List all pending notifications (for debugging)
    func listPendingNotifications() {
        notificationCenter.getPendingNotificationRequests { requests in
            print("📬 Pending notifications (\(requests.count)):")
            for request in requests {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    print("   - \(request.identifier): \(trigger.dateComponents)")
                } else {
                    print("   - \(request.identifier): \(String(describing: request.trigger))")
                }
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    
    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Handle notification action (when user taps or uses action buttons)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo
        
        print("📬 Notification action: \(actionIdentifier)")
        print("📬 User info: \(userInfo)")
        
        // Post notification for app to handle navigation
        switch actionIdentifier {
        case "CAPTURE_ACTION", UNNotificationDefaultActionIdentifier:
            // User tapped to capture - navigate to camera
            NotificationCenter.default.post(
                name: .didTapCaptureNotification,
                object: nil,
                userInfo: userInfo
            )
            
        case "DISMISS_ACTION":
            // User dismissed - just clear badge
            Task { @MainActor in
                self.clearBadge()
            }
            
        default:
            break
        }
        
        completionHandler()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    /// Posted when user taps on capture notification
    static let didTapCaptureNotification = Notification.Name("didTapCaptureNotification")
}
