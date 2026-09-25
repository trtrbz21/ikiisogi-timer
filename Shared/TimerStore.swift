import Foundation
import Observation
import WidgetKit

/// Persists timers on device as JSON in the App Group's UserDefaults,
/// so the widget extension reads the same timers as the app.
@Observable
final class TimerStore {
    static let appGroupID = "group.com.trtrbz21.IkiisogiTimer"

    private(set) var timers: [CountdownTimer]

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let key = "timers.v1"

    init(defaults: UserDefaults = UserDefaults(suiteName: TimerStore.appGroupID) ?? .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([CountdownTimer].self, from: data),
           !decoded.isEmpty {
            timers = decoded
        } else {
            timers = [.endOfDay]
        }
    }

    /// The timer shown on the home screen.
    var current: CountdownTimer { timers[0] }

    func save(_ timer: CountdownTimer) {
        if let index = timers.firstIndex(where: { $0.id == timer.id }) {
            timers[index] = timer
        } else {
            timers.append(timer)
        }
        persist()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(timers) else { return }
        defaults.set(data, forKey: key)
    }
}
