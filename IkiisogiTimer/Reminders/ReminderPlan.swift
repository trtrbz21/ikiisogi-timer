import Foundation

/// When a "N minutes left" reminder should fire for a timer. Pure so it can be unit tested.
struct ReminderPlan: Equatable {
    /// The lead time the user may enter, in minutes (up to one full day).
    static let allowedMinutes = 1...1_440
    static let defaultMinutes = 60

    let minutesLeft: Int
    /// Calendar components for the trigger: hour/minute for daily timers, a full date for one-time timers.
    let components: DateComponents
    let repeats: Bool

    /// Returns `nil` when a one-time reminder would already be in the past.
    static func make(
        for timer: CountdownTimer,
        minutesLeft: Int,
        now: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> ReminderPlan? {
        switch timer.repeatMode {
        case .daily:
            // Wrap around midnight: 60 minutes before 0:30 is 23:30.
            let deadline = timer.hour * 60 + timer.minute
            let fire = ((deadline - minutesLeft) % 1_440 + 1_440) % 1_440
            return ReminderPlan(
                minutesLeft: minutesLeft,
                components: DateComponents(hour: fire / 60, minute: fire % 60),
                repeats: true
            )
        case .once:
            guard let fire = calendar.date(byAdding: .minute, value: -minutesLeft, to: timer.onceDate), fire > now else {
                return nil
            }
            return ReminderPlan(
                minutesLeft: minutesLeft,
                components: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire),
                repeats: false
            )
        }
    }
}
