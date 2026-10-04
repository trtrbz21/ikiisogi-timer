import Foundation
import UserNotifications

/// Schedules local "N minutes left" notifications. Everything stays on the device.
enum ReminderScheduler {
    /// Asks for permission if it has not been decided yet. Returns whether notifications are allowed.
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        default:
            return false
        }
    }

    /// Replaces the pending reminder with one matching the current timer and lead time.
    /// Pass `nil` when reminders are off. Call after the timer or the setting changes, and on launch.
    static func reschedule(timer: CountdownTimer, minutesLeft: Int?, now: Date = .now) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard let minutesLeft, ReminderPlan.allowedMinutes.contains(minutesLeft) else { return }

        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional || status == .ephemeral else { return }

        guard let plan = ReminderPlan.make(for: timer, minutesLeft: minutesLeft, now: now) else { return }
        let content = UNMutableNotificationContent()
        content.title = timer.displayTitle
        content.body = String(localized: "あと\(plan.minutesLeft)分")
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: plan.components, repeats: plan.repeats)
        try? await center.add(UNNotificationRequest(identifier: "reminder", content: content, trigger: trigger))
    }
}
