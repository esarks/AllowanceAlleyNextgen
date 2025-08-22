//
//  NotificationsService.swift
//  AllowanceAlley
//

import Foundation
import UserNotifications
import Combine

class NotificationsService: ObservableObject {
    static let shared = NotificationsService()
    
    @Published var isAuthorized = false
    @Published var notificationPrefs: [String: NotificationPref] = [:] // userId -> prefs
    
    private let supabaseClient = SupabaseClient.shared
    private let authService = AuthService.shared
    private let choreService = ChoreService.shared
    
    private init() {}
    
    // MARK: - Permission Management
    
    func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
            }
            
            if granted {
                self?.scheduleRecurringNotifications()
            }
        }
    }
    
    func checkPermissions() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let authorized = settings.authorizationStatus == .authorized
        
        await MainActor.run {
            self.isAuthorized = authorized
        }
        
        return authorized
    }
    
    // MARK: - Notification Preferences
    
    func loadNotificationPrefs(for userId: String) async throws {
        let prefs: [NotificationPref] = try await supabaseClient.client.database
            .from("notification_prefs")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        
        if let pref = prefs.first {
            await MainActor.run {
                self.notificationPrefs[userId] = pref
            }
        } else {
            // Create default preferences
            let defaultPref = NotificationPref(userId: userId)
            try await saveNotificationPrefs(defaultPref)
        }
    }
    
    func saveNotificationPrefs(_ prefs: NotificationPref) async throws {
        let savedPrefs: NotificationPref = try await supabaseClient.insert("notification_prefs", values: prefs)
        
        await MainActor.run {
            self.notificationPrefs[prefs.userId] = savedPrefs
        }
    }
    
    func updateNotificationPrefs(_ prefs: NotificationPref) async throws {
        let updatedPrefs: NotificationPref = try await supabaseClient.update("notification_prefs", values: prefs, matching: "id", value: prefs.id)
        
        await MainActor.run {
            self.notificationPrefs[prefs.userId] = updatedPrefs
        }
    }
    
    // MARK: - Scheduling Notifications
    
    func scheduleChoreReminder(for instance: ChoreInstance, chore: Chore) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Chore Reminder"
        content.body = "\(chore.title) is due soon!"
        content.sound = .default
        content.badge = 1
        
        // Schedule 1 hour before due time
        let reminderTime = instance.dueAt.addingTimeInterval(-3600)
        guard reminderTime > Date() else { return }
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "chore_reminder_\(instance.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    func scheduleChoreOverdue(for instance: ChoreInstance, chore: Chore) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Chore Overdue"
        content.body = "\(chore.title) is overdue!"
        content.sound = .default
        content.badge = 1
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: instance.dueAt)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "chore_overdue_\(instance.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule overdue notification: \(error)")
            }
        }
    }
    
    func scheduleApprovalNotification(for instance: ChoreInstance, chore: Chore) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Chore Completed"
        content.body = "Your child completed '\(chore.title)' and needs approval!"
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "approval_needed_\(instance.id)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule approval notification: \(error)")
            }
        }
    }
    
    func scheduleRedemptionNotification(for redemption: Redemption, reward: Reward) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Reward Requested"
        content.body = "Your child wants to redeem '\(reward.title)'"
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "redemption_\(redemption.id)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule redemption notification: \(error)")
            }
        }
    }
    
    private func scheduleRecurringNotifications() {
        // Schedule daily check for due chores
        let content = UNMutableNotificationContent()
        content.title = "Daily Chore Check"
        content.body = "Don't forget to check your chores!"
        content.sound = .default
        
        var components = DateComponents()
        components.hour = 8 // 8 AM daily
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_chore_check",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule daily notification: \(error)")
            }
        }
    }
    
    // MARK: - Cancel Notifications
    
    func cancelNotification(for id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}