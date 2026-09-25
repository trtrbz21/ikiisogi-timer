import SwiftUI

struct TimerEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: CountdownTimer
    let onSave: (CountdownTimer) -> Void

    private let calendar = Calendar.autoupdatingCurrent

    init(timer: CountdownTimer, onSave: @escaping (CountdownTimer) -> Void) {
        _draft = State(initialValue: timer)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("タイトル") {
                    TextField(CountdownTimer.endOfDay.title, text: $draft.title)
                }

                Section {
                    Picker("繰り返し", selection: $draft.repeatMode) {
                        Text("毎日").tag(CountdownTimer.Repeat.daily)
                        Text("1回のみ").tag(CountdownTimer.Repeat.once)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                    switch draft.repeatMode {
                    case .daily:
                        DatePicker("締め時刻", selection: dailyTime, displayedComponents: .hourAndMinute)
                    case .once:
                        DatePicker("締め日時", selection: $draft.onceDate, in: Date.now..., displayedComponents: [.date, .hourAndMinute])
                    }
                } footer: {
                    switch draft.repeatMode {
                    case .daily:
                        Text("締め時刻を過ぎると、翌日の同じ時刻までのカウントを自動で始めます。")
                    case .once:
                        Text("締め日時を過ぎるとカウントを終了します。")
                    }
                }

                Section {
                    Button("初期設定に戻す", role: .destructive) {
                        draft = CountdownTimer(id: draft.id, title: CountdownTimer.endOfDay.title)
                    }
                }
            }
            .navigationTitle("タイマーを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(finalized(draft))
                        dismiss()
                    }
                }
            }
            .onChange(of: draft.repeatMode) { _, mode in
                // Start "once" from the upcoming daily deadline instead of a date already in the past.
                if mode == .once, draft.onceDate <= .now {
                    var daily = draft
                    daily.repeatMode = .daily
                    draft.onceDate = Countdown.deadline(for: daily, now: .now, calendar: calendar)
                }
            }
        }
    }

    /// Bridges the stored hour/minute to the Date the picker needs.
    private var dailyTime: Binding<Date> {
        Binding {
            calendar.date(bySettingHour: draft.hour, minute: draft.minute, second: 0, of: .now) ?? .now
        } set: { date in
            let components = calendar.dateComponents([.hour, .minute], from: date)
            draft.hour = components.hour ?? 0
            draft.minute = components.minute ?? 0
        }
    }

    private func finalized(_ timer: CountdownTimer) -> CountdownTimer {
        var timer = timer
        timer.title = timer.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if timer.title.isEmpty {
            timer.title = CountdownTimer.endOfDay.title
        }
        // Drop seconds so the countdown lands exactly on the minute the user picked.
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: timer.onceDate)
        timer.onceDate = calendar.date(from: components) ?? timer.onceDate
        timer.configuredAt = .now
        return timer
    }
}

#Preview {
    TimerEditView(timer: .endOfDay) { _ in }
}
