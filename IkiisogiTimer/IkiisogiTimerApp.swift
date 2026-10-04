import SwiftUI

@main
struct IkiisogiTimerApp: App {
    @State private var store = TimerStore()
    @AppStorage(SettingsKey.appearance) private var appearance: Appearance = .system
    @AppStorage(SettingsKey.reminderEnabled) private var reminderEnabled = false
    @AppStorage(SettingsKey.reminderMinutes) private var reminderMinutes = ReminderPlan.defaultMinutes
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(store)
                .preferredColorScheme(appearance.colorScheme)
                // Keep the pending reminder in step with the timer and the chosen lead time.
                // Also refreshed on every activation, so a one-time timer drops reminders that have passed
                // and a permission granted in Settings takes effect.
                .task(id: ReminderKey(timer: store.current, minutesLeft: reminderEnabled ? reminderMinutes : nil, isActive: scenePhase == .active)) {
                    await ReminderScheduler.reschedule(timer: store.current, minutesLeft: reminderEnabled ? reminderMinutes : nil)
                }
        }
    }
}

private struct ReminderKey: Equatable {
    let timer: CountdownTimer
    let minutesLeft: Int?
    let isActive: Bool
}
