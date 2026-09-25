import Foundation
import Testing
@testable import IkiisogiTimer

@MainActor
struct CountdownTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }()

    private func date(_ day: Int, _ hour: Int, _ minute: Int, _ second: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute, second: second))!
    }

    private func reading(_ timer: CountdownTimer, _ unit: DisplayUnit, at now: Date) -> Countdown.Reading {
        Countdown.reading(for: timer, unit: unit, now: now, calendar: calendar)
    }

    @Test func minutesAreRoundedDown() {
        let timer = CountdownTimer(title: "", hour: 0, minute: 0)
        // 23:58:30 → 90 seconds left → 1 minute
        #expect(reading(timer, .minutes, at: date(25, 23, 58, 30)) == .init(value: 1, unit: .minutes, isFinished: false))
    }

    @Test func switchesToSecondsUnderOneMinute() {
        let timer = CountdownTimer(title: "", hour: 0, minute: 0)
        #expect(reading(timer, .minutes, at: date(25, 23, 59, 1)) == .init(value: 59, unit: .seconds, isFinished: false))
        #expect(reading(timer, .minutes, at: date(25, 23, 59, 0)) == .init(value: 1, unit: .minutes, isFinished: false))
    }

    @Test func secondsUnit() {
        let timer = CountdownTimer(title: "", hour: 0, minute: 0)
        // 19:31:00 → 4h29m = 16,140 seconds
        #expect(reading(timer, .seconds, at: date(25, 19, 31)) == .init(value: 16_140, unit: .seconds, isFinished: false))
    }

    @Test func dailyRollsOverAfterDeadline() {
        let timer = CountdownTimer(title: "", hour: 0, minute: 0)
        // Exactly midnight: the next deadline is the following midnight.
        #expect(reading(timer, .minutes, at: date(26, 0, 0)).value == 1_440)
    }

    @Test func dailyDeadlineAfterMidnightCountsToNextDay() {
        let timer = CountdownTimer(title: "", hour: 2, minute: 0)
        #expect(reading(timer, .minutes, at: date(25, 23, 0)).value == 180)
    }

    @Test func onceFinishesAndStays() {
        let timer = CountdownTimer(title: "", repeatMode: .once, onceDate: date(25, 12, 0), configuredAt: date(25, 10, 0))
        #expect(reading(timer, .minutes, at: date(25, 11, 0)) == .init(value: 60, unit: .minutes, isFinished: false))
        #expect(reading(timer, .minutes, at: date(25, 12, 0)).isFinished)
        #expect(reading(timer, .minutes, at: date(26, 12, 0)) == .init(value: 0, unit: .minutes, isFinished: true))
    }

    @Test func onceCanSpanMultipleDays() {
        let timer = CountdownTimer(title: "", repeatMode: .once, onceDate: date(30, 0, 0))
        #expect(reading(timer, .minutes, at: date(25, 0, 0)).value == 5 * 1_440)
    }

    @Test func progress() {
        let daily = CountdownTimer(title: "", hour: 0, minute: 0)
        #expect(Countdown.progress(for: daily, now: date(25, 12, 0), calendar: calendar) == 0.5)

        let once = CountdownTimer(title: "", repeatMode: .once, onceDate: date(25, 12, 0), configuredAt: date(25, 10, 0))
        #expect(Countdown.progress(for: once, now: date(25, 11, 0), calendar: calendar) == 0.5)
        #expect(Countdown.progress(for: once, now: date(25, 13, 0), calendar: calendar) == 1)
    }

    @Test func defaultTitleFollowsLanguage() {
        let timer = CountdownTimer.endOfDay
        #expect(timer.title.isEmpty)
        #expect(timer.displayTitle == CountdownTimer.defaultTitle)

        var custom = timer
        custom.title = "締め切り"
        #expect(custom.displayTitle == "締め切り")
    }

    @Test func storePersistsTimers() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = TimerStore(defaults: defaults)
        var timer = store.current
        timer.title = "締め切り"
        timer.hour = 18
        store.save(timer)

        let reloaded = TimerStore(defaults: defaults)
        #expect(reloaded.current == timer)
    }
}
