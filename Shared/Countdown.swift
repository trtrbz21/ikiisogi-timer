import Foundation

enum DisplayUnit: String, CaseIterable, Sendable {
    case minutes
    case seconds

    var toggled: DisplayUnit { self == .minutes ? .seconds : .minutes }
}

/// Pure time math for a timer at a given instant. Kept free of UI so it can be unit tested
/// and reused by widgets and notifications later.
enum Countdown {
    struct Reading: Equatable {
        /// Whole units remaining, always rounded down.
        let value: Int
        /// The unit actually shown. May be `.seconds` even when minutes were requested (under one minute left).
        let unit: DisplayUnit
        let isFinished: Bool
    }

    /// The instant the timer is currently counting towards.
    /// For `.daily` this is the next occurrence strictly after `now`, so hitting the deadline rolls to tomorrow.
    static func deadline(for timer: CountdownTimer, now: Date, calendar: Calendar = .autoupdatingCurrent) -> Date {
        switch timer.repeatMode {
        case .once:
            return timer.onceDate
        case .daily:
            let components = DateComponents(hour: timer.hour, minute: timer.minute, second: 0)
            return calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime)
                ?? now.addingTimeInterval(86_400)
        }
    }

    /// The instant the current countdown period began, used for the progress bar.
    static func periodStart(for timer: CountdownTimer, now: Date, calendar: Calendar = .autoupdatingCurrent) -> Date {
        switch timer.repeatMode {
        case .once:
            return min(timer.configuredAt, timer.onceDate)
        case .daily:
            let end = deadline(for: timer, now: now, calendar: calendar)
            return calendar.date(byAdding: .day, value: -1, to: end) ?? end.addingTimeInterval(-86_400)
        }
    }

    static func reading(
        for timer: CountdownTimer,
        unit: DisplayUnit,
        now: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Reading {
        let remaining = deadline(for: timer, now: now, calendar: calendar).timeIntervalSince(now)
        guard remaining > 0 else {
            return Reading(value: 0, unit: unit, isFinished: true)
        }
        let seconds = Int(remaining.rounded(.down))
        if unit == .minutes, seconds >= 60 {
            return Reading(value: seconds / 60, unit: .minutes, isFinished: false)
        }
        return Reading(value: seconds, unit: .seconds, isFinished: false)
    }

    /// Fraction of the current period that has elapsed, in 0...1.
    static func progress(for timer: CountdownTimer, now: Date, calendar: Calendar = .autoupdatingCurrent) -> Double {
        let start = periodStart(for: timer, now: now, calendar: calendar)
        let end = deadline(for: timer, now: now, calendar: calendar)
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 1 }
        return min(max(now.timeIntervalSince(start) / total, 0), 1)
    }
}
