import Foundation
import UserNotifications
import Combine

@MainActor
final class NotificationsService: ObservableObject {
    static let shared = NotificationsService()
    
    @Published var isAuthorized = false
    @Published var notificationSettings: [String: NotificationSettings] = [:]
    
    private init() {}
    
    func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
            Task { @MainActor in self?.isAuthorized = granted }
        }
    }
    
    func checkPermissions() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let authorized = settings.authorizationStatus == .authorized
        isAuthorized = authorized
        return authorized
    }
    
    func scheduleChoreReminder(choreId: String, childId: String, dueDate: Date) {
        guard isAuthorized else { return }
        let content = UNMutableNotificationContent()
        content.title = "Chore Due Soon"
        content.body = "You have a chore due soon. Don't forget to complete it!"
        content.sound = .default
        let triggerDate = Calendar.current.date(byAdding: .hour, value: -1, to: dueDate) ?? dueDate
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: triggerDate), repeats: false)
        let request = UNNotificationRequest(identifier: "chore_reminder_\(choreId)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleApprovalNotification(for parentId: String) {
        guard isAuthorized else { return }
        let content = UNMutableNotificationContent()
        content.title = "Chore Completed"
        content.body = "A child has completed a chore and needs your approval!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "approval_needed_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelNotification(identifier: String) { UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier]) }
    func cancelAllNotifications() { UNUserNotificationCenter.current().removeAllPendingNotificationRequests() }
}

struct NotificationSettings {
    var dueSoonMinutes: Int = 60
    var allowReminders: Bool = true
}
