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

    /// Replaces all pending reminders with ones matching the current timer and selection.
    /// Call after the timer or the selection changes, and on launch.
    static func reschedule(timer: CountdownTimer, minutes: Set<Int>, now: Date = .now) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard !minutes.isEmpty else { return }

        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional || status == .ephemeral else { return }

        for plan in minutes.compactMap({ ReminderPlan.make(for: timer, minutesLeft: $0, now: now) }) {
            let content = UNMutableNotificationContent()
            content.title = timer.displayTitle
            content.body = String(localized: "あと\(plan.minutesLeft)分")
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: plan.components, repeats: plan.repeats)
            let request = UNNotificationRequest(identifier: "reminder.\(plan.minutesLeft)", content: content, trigger: trigger)
            try? await center.add(request)
        }
    }
}
