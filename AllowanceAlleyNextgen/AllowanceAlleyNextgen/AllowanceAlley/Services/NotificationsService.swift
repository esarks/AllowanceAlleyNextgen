import Foundation
import UserNotifications
import Combine

@MainActor
final class NotificationsService: ObservableObject {
    static let shared = NotificationsService()

    @Published var isAuthorized: Bool = false
    @Published var notificationPrefs: [String: NotificationPref] = [:]

    private init() {}

    func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
            Task { @MainActor in
                self?.isAuthorized = granted
            }
        }
    }

    func checkPermissions() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let ok = settings.authorizationStatus == .authorized
        self.isAuthorized = ok
        return ok
    }

    func loadNotificationPrefs(for userId: String) async throws {
        if notificationPrefs[userId] == nil {
            notificationPrefs[userId] = NotificationPref(userId: userId)
        }
    }

    func saveNotificationPrefs(_ prefs: NotificationPref) async throws {
        notificationPrefs[prefs.userId] = prefs
    }

    func updateNotificationPrefs(_ prefs: NotificationPref) async throws {
        notificationPrefs[prefs.userId] = prefs
    }

    // Scheduling (no-ops for stubbed project—safe to leave as placeholders)
    func scheduleChoreReminder(for _: Any, chore _: Any) {}
    func scheduleChoreOverdue(for _: Any, chore _: Any) {}
    func scheduleApprovalNotification(for _: Any, chore _: Any) {}
    func scheduleRedemptionNotification(for _: Redemption, reward _: Reward) {}

    func cancelNotification(for id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
