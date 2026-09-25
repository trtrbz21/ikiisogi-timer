import SwiftUI

@main
struct IkiisogiTimerApp: App {
    @State private var store = TimerStore()
    @AppStorage(SettingsKey.appearance) private var appearance: Appearance = .system

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(store)
                .preferredColorScheme(appearance.colorScheme)
        }
    }
}
