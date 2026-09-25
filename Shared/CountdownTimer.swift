import Foundation

/// A single countdown target. The app shows one timer in v1, but storage is a list
/// so multiple timers can be added later without a data migration.
struct CountdownTimer: Codable, Identifiable, Equatable, Sendable {
    enum Repeat: String, Codable, CaseIterable, Sendable {
        /// Counts down to `hour:minute` every day, rolling over to the next day once passed.
        case daily
        /// Counts down to `onceDate` a single time, then stays finished.
        case once
    }

    var id: UUID
    var title: String
    var repeatMode: Repeat
    var hour: Int
    var minute: Int
    var onceDate: Date
    /// When the timer was last configured. Used as the start of the progress bar for `.once`.
    var configuredAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        repeatMode: Repeat = .daily,
        hour: Int = 0,
        minute: Int = 0,
        onceDate: Date = .now,
        configuredAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.repeatMode = repeatMode
        self.hour = hour
        self.minute = minute
        self.onceDate = onceDate
        self.configuredAt = configuredAt
    }

    static var endOfDay: CountdownTimer {
        CountdownTimer(title: String(localized: "今日の終わりまで"))
    }
}
