import SwiftUI

@main
struct IkiisogiTimerApp: App {
    @State private var store = TimerStore()
    @AppStorage(SettingsKey.appearance) private var appearance: Appearance = .system
    @AppStorage(SettingsKey.reminders) private var remindersRaw = ""
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(store)
                .preferredColorScheme(appearance.colorScheme)
                // Keep pending reminders in step with the timer and the chosen lead times.
                // Also refreshed on every activation, so a one-time timer drops reminders that have passed
                // and a permission granted in Settings takes effect.
                .task(id: ReminderKey(timer: store.current, selection: remindersRaw, isActive: scenePhase == .active)) {
                    await ReminderScheduler.reschedule(timer: store.current, minutes: ReminderSelection.decode(remindersRaw))
                }
        }
    }
}

private struct ReminderKey: Equatable {
    let timer: CountdownTimer
    let selection: String
    let isActive: Bool
}
