# AGENTS.md

Guidance for AI coding agents (and humans) working on this repository.

## Product

**生き急ぎタイマー** (working English name TBD) — an iPhone app that shows the time left until the end of the day (or a user-set deadline) in a single unit only: "あと269分" or "あと16,140秒". The point is to make time feel scarce; never show mixed units like "4時間29分".

The owner communicates in Japanese. Write user-facing strings and explanations to the owner in Japanese; code, comments, and commit messages in English.

## Tech stack

- SwiftUI, Swift 6, iOS 18.0+, Xcode 27
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` on the app target (types are main-actor by default)
- No third-party dependencies. Keep it that way unless there is a strong reason.
- iPhone only for now (`TARGETED_DEVICE_FAMILY = 1`), but keep layouts adaptive so iPad can be enabled later.

## Commands

`xcode-select` on this Mac may still point to Command Line Tools. Prefix commands with
`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` if `xcodebuild` complains.

```bash
# Run unit tests
xcodebuild test -project IkiisogiTimer.xcodeproj -scheme IkiisogiTimer \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -derivedDataPath build

# Build only
xcodebuild build -project IkiisogiTimer.xcodeproj -scheme IkiisogiTimer \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -derivedDataPath build

# Install and launch on a booted simulator
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/IkiisogiTimer.app
xcrun simctl launch booted com.trtrbz21.IkiisogiTimer
```

Always run the tests after changing anything in `Shared/`. For UI changes, launch in the simulator and check both light and dark appearance (`xcrun simctl ui booted appearance dark|light`).

## Project layout

```
IkiisogiTimer/                 App target
  IkiisogiTimerApp.swift       App entry, injects TimerStore, applies appearance setting
  Views/
    HomeView.swift             Main countdown screen (CountdownFace, ProgressLine)
    TimerEditView.swift        Edit title / repeat mode / deadline
    SettingsView.swift         Display unit, keep screen on, theme, links, version
  Assets.xcassets              AppIcon, AccentColor
  InfoPlist.xcstrings          Localized home screen name (ja: 生き急ぎタイマー, en: Live in a Hurry)
  PrivacyInfo.xcprivacy        Privacy manifest (UserDefaults reason CA92.1)
Shared/                        Compiled into BOTH the app and the widget extension
  Countdown.swift              Pure time math: deadline, reading (value + unit), progress
  CountdownTimer.swift         Timer data (daily / once)
  TimerStore.swift             Persistence (JSON in App Group UserDefaults), reloads widgets on save
  AppSettings.swift            @AppStorage keys, Appearance, DisplayUnit labels, AppLinks
  Localizable.xcstrings        String catalog for app AND widget (source: ja, translations: en)
IkiisogiTimerWidget/           Widget extension target
  IkiisogiTimerWidgetBundle.swift
  CountdownWidget.swift        Intent (unit: 分/秒), timeline provider, views for all families
IkiisogiTimerTests/            Swift Testing unit tests
Config/                        Entitlements and the widget's Info.plist (not compiled)
docs/                          GitHub Pages: support page and privacy policy (ja), docs/en/ (en)
AppStore/metadata.md           App Store Connect text drafts (ja/en)
Tools/generate-app-icon.swift  Renders the app icon PNGs
```

The Xcode project uses **file-system synchronized groups**: any file added under `IkiisogiTimer/`, `Shared/`, `IkiisogiTimerWidget/` or `IkiisogiTimerTests/` is picked up automatically by the owning target(s). Do not add file references to `project.pbxproj` by hand. Code the widget needs must live in `Shared/`.

### Widget notes

- App Group: `group.com.trtrbz21.IkiisogiTimer` (app and widget entitlements in `Config/`). `TimerStore()` uses it by default.
- The app target defaults to `MainActor` isolation; the widget target does not. Code in `Shared/` must compile under both, so keep it free of UI-only APIs (`UIApplication` etc.).
- The remaining-time text uses `Text(.currentDate, format: .offset(to:allowedFields:maxFieldCount:sign:))` (iOS 18), which the system updates every second. `[.minute, .second]` with `maxFieldCount: 1` reproduces the app's rules (floor, seconds under one minute). Do not replace it with `Text(timerInterval:)`, which shows `h:mm:ss`.
- Timeline entries exist only for the ring (every 5 minutes, 6 hours ahead) and for deadline rollovers. The linear progress uses `ProgressView(timerInterval:)` and is live.
- Per-widget background (自動/白/黒/濃紺, home screen families only): the content gets a forced `colorScheme`, and the `containerBackground` color is set explicitly because the system draws it outside the content's environment.
- Do not use `ProgressView(...).progressViewStyle(.circular)` for the ring; it renders a thick system gauge. The ring is drawn with `Circle().trim` like the app icon.

## Behavior rules (decided with the owner — do not change without asking)

- Minutes are **rounded down**. When less than 60 seconds remain in minutes mode, show seconds automatically.
- Tapping the number toggles minutes ⇄ seconds and persists the choice.
- **Daily** timers count to the next occurrence of `hour:minute` strictly after now; at the deadline they roll over to the next day. A deadline after midnight (e.g. 2:00) counts into the next day.
- **Once** timers count to a specific date and time and stay at "終了 0" after it passes.
- Time zone always follows the device (`Calendar.autoupdatingCurrent`).
- Appearance follows iOS by default; the user can force light, dark, or navy (濃紺, `Color.navy` #0E1A33, dark scheme) in Settings.
- Data is stored on device only. No accounts, no analytics, no network.
- v1 has **no ads**. Ads and a remove-ads purchase (or a Pro unlock) come later.

## Code conventions

- Put time math in `Countdown` as pure functions that take `now` and `calendar` parameters, and cover it with tests. Views should not compute deadlines themselves.
- Tests use Swift Testing (`import Testing`, `@Test`, `#expect`), are marked `@MainActor`, and use a fixed `Asia/Tokyo` calendar.
- `TimerStore` already stores an array of timers so multiple timers can be added without a migration. Keep new fields backward compatible with existing saved JSON (give them defaults or decode them as optional).
- Write user-facing text as Japanese string literals in `Text(...)` / `String(localized:)` and add the English translation to `Shared/Localizable.xcstrings`. Do not build sentences by concatenating strings; interpolate instead so word order can change (e.g. `"あと%@"` → `"%@ left"`).
- To check that every key has a translation, build and compare the keys in `build/**/*.stringsdata` with the catalog (Xcode only syncs the catalog when opened in the IDE).
- Store an empty `CountdownTimer.title` for the default and show `displayTitle`, so the default title follows the device language.
- Units next to the big number use `DisplayUnit.shortLabel` ("min"/"sec" in English); pickers use `label` ("Minutes"/"Seconds").
- Use `.monospacedDigit()` on changing numbers so the layout does not jitter.
- Design direction is "refined simplicity": system font (SF Pro) in thin or light weights, monochrome (plus the navy theme), generous whitespace, no decorative color. Match what is already there.

## Roadmap

See the checklist in `README.md`. Live Activities can reuse the App Group and `Shared/` code the widget already uses.

## Release notes

### App Store metadata (decided with the owner)

| Locale | Name | Subtitle |
|---|---|---|
| Japanese (primary) | 生き急ぎタイマー | 今日の残り時間は、あと何秒？ |
| English | Live in a Hurry | Seconds left in your day |

- Fallback English name if taken: `Live in a Hurry: Minutes Left`.
- Only publish the English store listing together with an English-localized app.
- Seller name / privacy policy operator: Kazuki Watanabe. Support contact: kazuki.brbr@gmail.com.


- Bundle IDs: `com.trtrbz21.IkiisogiTimer` and `com.trtrbz21.IkiisogiTimer.Widget` (still changeable until registered in App Store Connect). The App Group must be registered in the developer portal once a team is set.
- `DEVELOPMENT_TEAM` is empty until the owner joins the Apple Developer Program.
- Bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` for each release, in both the app and widget targets (they must match).
