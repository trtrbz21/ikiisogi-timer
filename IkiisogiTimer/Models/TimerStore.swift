import Foundation
import Observation

/// Persists timers on device as JSON in UserDefaults.
/// Swap `defaults` for an App Group suite when the widget extension is added.
@Observable
final class TimerStore {
    private(set) var timers: [CountdownTimer]

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let key = "timers.v1"

    init(defaults: UserDefaults = .standard) {
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
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(timers) else { return }
        defaults.set(data, forKey: key)
    }
}
