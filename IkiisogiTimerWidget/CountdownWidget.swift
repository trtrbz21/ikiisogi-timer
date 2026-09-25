import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Configuration

enum WidgetUnit: String, AppEnum {
    case minutes
    case seconds

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "表示単位" }
    static var caseDisplayRepresentations: [WidgetUnit: DisplayRepresentation] {
        [.minutes: "分", .seconds: "秒"]
    }
}

struct CountdownWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "残り時間" }
    static var description: IntentDescription { "締め時刻までの残り時間を表示します。" }

    @Parameter(title: "表示単位", default: .minutes)
    var unit: WidgetUnit
}

// MARK: - Timeline

struct CountdownEntry: TimelineEntry {
    let date: Date
    let timer: CountdownTimer
    let unit: WidgetUnit

    var deadline: Date { Countdown.deadline(for: timer, now: date) }
    var periodStart: Date { Countdown.periodStart(for: timer, now: date) }
    var isFinished: Bool { timer.repeatMode == .once && date >= timer.onceDate }
}

struct CountdownProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(date: .now, timer: .endOfDay, unit: .minutes)
    }

    func snapshot(for configuration: CountdownWidgetIntent, in context: Context) async -> CountdownEntry {
        CountdownEntry(date: .now, timer: TimerStore().current, unit: configuration.unit)
    }

    /// The remaining-time text and the progress line update themselves every second. Entries are
    /// only needed for the ring (every 5 minutes) and for the moments the deadline changes:
    /// when a daily timer rolls over, or a one-time timer ends.
    func timeline(for configuration: CountdownWidgetIntent, in context: Context) async -> Timeline<CountdownEntry> {
        let timer = TimerStore().current
        let now = Date.now
        let horizon = now.addingTimeInterval(6 * 60 * 60)
        let step: TimeInterval = 5 * 60

        var dates: Set<Date> = [now]
        var tick = Date(timeIntervalSinceReferenceDate: (now.timeIntervalSinceReferenceDate / step).rounded(.up) * step)
        while tick <= horizon {
            dates.insert(tick)
            tick.addTimeInterval(step)
        }

        let policy: TimelineReloadPolicy
        switch timer.repeatMode {
        case .daily:
            var deadline = Countdown.deadline(for: timer, now: now)
            while deadline <= horizon {
                dates.insert(deadline)
                deadline = Countdown.deadline(for: timer, now: deadline)
            }
            policy = .atEnd
        case .once:
            dates = dates.filter { $0 < timer.onceDate }
            if timer.onceDate > now {
                dates.insert(timer.onceDate)
            }
            policy = timer.onceDate > horizon ? .atEnd : .never
        }

        let entries = dates.sorted().map { CountdownEntry(date: $0, timer: timer, unit: configuration.unit) }
        return Timeline(entries: entries, policy: policy)
    }
}

// MARK: - Views

struct CountdownWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CountdownEntry

    var body: some View {
        switch family {
        case .systemMedium: medium
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        case .accessoryInline: inline
        default: small
        }
    }

    // Home screen / StandBy

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(entry.timer.title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer(minLength: 0)
            Text(entry.isFinished ? "終了" : "あと")
                .font(.caption)
                .foregroundStyle(.secondary)
            remaining
                .font(.system(size: 36, weight: .light))
            Spacer(minLength: 0)
            progressLine
        }
    }

    private var medium: some View {
        HStack(spacing: 20) {
            ring(lineWidth: 6)
                .frame(width: 96, height: 96)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.timer.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(entry.isFinished ? "終了" : "あと")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                remaining
                    .font(.system(size: 44, weight: .light))
                Spacer(minLength: 0)
                Text(deadlineDescription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // Lock screen

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            ring(lineWidth: 4)
                .padding(3)
            remaining
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 8)
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.timer.title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(entry.isFinished ? "終了" : "あと")
                    .font(.caption)
                remaining
                    .font(.system(size: 22, weight: .medium))
            }
            progressLine
        }
    }

    private var inline: some View {
        if entry.isFinished {
            Text("\(entry.timer.title) 終了")
        } else {
            Text("あと\(Text(.currentDate, format: offsetFormat))")
        }
    }

    // Parts

    /// "269分" / "16,140秒", updated live by the system. Minutes are rounded down and
    /// switch to seconds under one minute, matching `Countdown.reading` in the app.
    @ViewBuilder
    private var remaining: some View {
        Group {
            if entry.isFinished {
                Text("0\(Text(entry.unit == .seconds ? "秒" : "分"))")
            } else {
                Text(.currentDate, format: offsetFormat)
            }
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.4)
    }

    private var offsetFormat: SystemFormatStyle.DateOffset {
        switch entry.unit {
        case .minutes: .offset(to: entry.deadline, allowedFields: [.minute, .second], maxFieldCount: 1, sign: .never)
        case .seconds: .offset(to: entry.deadline, allowedFields: [.second], maxFieldCount: 1, sign: .never)
        }
    }

    private var progressLine: some View {
        Group {
            if entry.isFinished {
                ProgressView(value: 1)
            } else {
                ProgressView(timerInterval: entry.periodStart...entry.deadline, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
            }
        }
        .progressViewStyle(.linear)
        .tint(.primary)
    }

    /// The remaining share of the period as an arc, drawn like the app icon:
    /// it ends at 12 o'clock and shrinks clockwise as time passes.
    private func ring(lineWidth: CGFloat) -> some View {
        let remaining = entry.isFinished ? 0 : 1 - Countdown.progress(for: entry.timer, now: entry.date)
        return ZStack {
            Circle()
                .stroke(.primary.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 1 - remaining, to: 1)
                .stroke(.primary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .padding(lineWidth / 2)
    }

    private var deadlineDescription: String {
        switch entry.timer.repeatMode {
        case .daily:
            let time = Calendar.autoupdatingCurrent
                .date(bySettingHour: entry.timer.hour, minute: entry.timer.minute, second: 0, of: entry.date) ?? entry.date
            return String(localized: "毎日 \(time.formatted(date: .omitted, time: .shortened)) まで")
        case .once:
            return String(localized: "\(entry.timer.onceDate.formatted(date: .numeric, time: .shortened)) まで")
        }
    }
}

// MARK: - Widget

struct CountdownWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "CountdownWidget", intent: CountdownWidgetIntent.self, provider: CountdownProvider()) { entry in
            CountdownWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(uiColor: .systemBackground)
                }
        }
        .configurationDisplayName("残り時間")
        .description("締め時刻までの残り時間を、分または秒で表示します。")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

#Preview(as: .systemSmall) {
    CountdownWidget()
} timeline: {
    CountdownEntry(date: .now, timer: .endOfDay, unit: .minutes)
    CountdownEntry(date: .now, timer: .endOfDay, unit: .seconds)
}

#Preview(as: .systemMedium) {
    CountdownWidget()
} timeline: {
    CountdownEntry(date: .now, timer: .endOfDay, unit: .minutes)
}
