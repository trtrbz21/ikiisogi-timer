import SwiftUI

struct HomeView: View {
    @Environment(TimerStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(SettingsKey.displayUnit) private var unit: DisplayUnit = .minutes
    @AppStorage(SettingsKey.keepScreenOn) private var keepScreenOn = false
    @AppStorage(SettingsKey.appearance) private var appearance: Appearance = .system

    @State private var isEditing = false
    @State private var isShowingSettings = false
    /// Aligns ticks to whole seconds so the display changes exactly on the second.
    @State private var tickStart = Date(timeIntervalSinceReferenceDate: Date.now.timeIntervalSinceReferenceDate.rounded(.down))

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: tickStart, by: 1)) { context in
                CountdownFace(timer: store.current, unit: unit, now: context.date) {
                    unit = unit.toggled
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("設定", systemImage: "gearshape") { isShowingSettings = true }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("タイマーを編集", systemImage: "slider.horizontal.3") { isEditing = true }
                }
            }
            .background {
                if let color = appearance.backgroundColor {
                    color.ignoresSafeArea()
                }
            }
            .tint(.primary)
        }
        .sensoryFeedback(.selection, trigger: unit)
        .sheet(isPresented: $isEditing) {
            TimerEditView(timer: store.current) { store.save($0) }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        .onAppear(perform: updateIdleTimer)
        .onChange(of: keepScreenOn) { updateIdleTimer() }
        .onChange(of: scenePhase) { updateIdleTimer() }
    }

    private func updateIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = keepScreenOn && scenePhase == .active
    }
}

/// The large "あと ◯ 分" readout with the deadline and a progress line underneath.
struct CountdownFace: View {
    let timer: CountdownTimer
    let unit: DisplayUnit
    let now: Date
    let onToggleUnit: () -> Void

    private var reading: Countdown.Reading {
        Countdown.reading(for: timer, unit: unit, now: now)
    }

    var body: some View {
        let reading = reading
        let progress = Countdown.progress(for: timer, now: now)

        ZStack {
            // The number itself sits at the exact center of the screen;
            // the title and "あと" hang above it instead of pushing it down.
            Button(action: onToggleUnit) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(reading.value, format: .number)
                        .font(.system(size: 104, weight: .thin))
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))
                        .lineLimit(1)
                        .minimumScaleFactor(0.3)
                    Text(reading.unit.shortLabel)
                        .font(.system(size: 28, weight: .light))
                }
                .frame(maxWidth: .infinity)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("タップで分と秒の表示を切り替えます")
            .overlay(alignment: .top) {
                VStack(spacing: 28) {
                    Text(timer.displayTitle)
                        .font(.subheadline.weight(.medium))
                        .multilineTextAlignment(.center)
                    Text(reading.isFinished ? "終了" : "あと")
                        .font(.title3.weight(.light))
                }
                .foregroundStyle(.secondary)
                .alignmentGuide(.top) { $0[.bottom] + 4 }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()

            VStack(spacing: 10) {
                ProgressLine(progress: progress)
                HStack {
                    Text(deadlineDescription)
                    Spacer()
                    Text("\(Int(progress * 100))% 経過")
                        .monospacedDigit()
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding(.bottom, 24)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .padding(.horizontal, 32)
        .animation(.snappy, value: reading)
    }

    private var deadlineDescription: String {
        switch timer.repeatMode {
        case .daily:
            let time = Calendar.autoupdatingCurrent
                .date(bySettingHour: timer.hour, minute: timer.minute, second: 0, of: now) ?? now
            return String(localized: "毎日 \(time.formatted(date: .omitted, time: .shortened)) まで")
        case .once:
            return String(localized: "\(timer.onceDate.formatted(date: .numeric, time: .shortened)) まで")
        }
    }
}

private struct ProgressLine: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(.primary)
                    .frame(width: proxy.size.width * progress)
            }
        }
        .frame(height: 2)
        .accessibilityHidden(true)
    }
}

#Preview {
    HomeView()
        .environment(TimerStore(defaults: UserDefaults(suiteName: "preview")!))
}
