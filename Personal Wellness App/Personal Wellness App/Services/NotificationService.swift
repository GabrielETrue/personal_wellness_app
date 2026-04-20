import Foundation
import UserNotifications

struct NotificationService {

    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("NotificationService: permission request failed: \(error)")
            return false
        }
    }

    static func scheduleDailySummary(at hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily_wellness_summary"])

        let content = UNMutableNotificationContent()
        content.title = "Your Daily Wellness Insight"
        content.body = "Your morning summary is ready. Tap to read."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily_wellness_summary",
            content: content,
            trigger: trigger
        )
        center.add(request) { error in
            if let error { print("NotificationService: schedule failed: \(error)") }
        }
    }

    static func cancelDailySummary() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["daily_wellness_summary"])
    }

    static func sendImmediateNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("NotificationService: immediate notification failed: \(error)") }
        }
    }
}
