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

Always run the tests after changing anything in `Models/`. For UI changes, launch in the simulator and check both light and dark appearance (`xcrun simctl ui booted appearance dark|light`).

## Project layout

```
IkiisogiTimer/
  IkiisogiTimerApp.swift     App entry, injects TimerStore, applies appearance setting
  Models/
    Countdown.swift          Pure time math: deadline, reading (value + unit), progress
    CountdownTimer.swift     Timer data (daily / once)
    TimerStore.swift         Persistence (JSON in UserDefaults)
    AppSettings.swift        @AppStorage keys, Appearance, DisplayUnit labels
  Views/
    HomeView.swift           Main countdown screen (CountdownFace, ProgressLine)
    TimerEditView.swift      Edit title / repeat mode / deadline
    SettingsView.swift       Display unit, keep screen on, theme, version
  Assets.xcassets            AppIcon, AccentColor
  Localizable.xcstrings      String catalog (source language: ja)
  PrivacyInfo.xcprivacy      Privacy manifest (UserDefaults reason CA92.1)
IkiisogiTimerTests/          Swift Testing unit tests
```

The Xcode project uses **file-system synchronized groups**: any file added under `IkiisogiTimer/` or `IkiisogiTimerTests/` is picked up automatically. Do not add file references to `project.pbxproj` by hand.

## Behavior rules (decided with the owner — do not change without asking)

- Minutes are **rounded down**. When less than 60 seconds remain in minutes mode, show seconds automatically.
- Tapping the number toggles minutes ⇄ seconds and persists the choice.
- **Daily** timers count to the next occurrence of `hour:minute` strictly after now; at the deadline they roll over to the next day. A deadline after midnight (e.g. 2:00) counts into the next day.
- **Once** timers count to a specific date and time and stay at "終了 0" after it passes.
- Time zone always follows the device (`Calendar.autoupdatingCurrent`).
- Appearance follows iOS by default; the user can force light or dark in Settings.
- Data is stored on device only. No accounts, no analytics, no network.
- v1 has **no ads**. Ads and a remove-ads purchase (or a Pro unlock) come later.

## Code conventions

- Put time math in `Countdown` as pure functions that take `now` and `calendar` parameters, and cover it with tests. Views should not compute deadlines themselves.
- Tests use Swift Testing (`import Testing`, `@Test`, `#expect`), are marked `@MainActor`, and use a fixed `Asia/Tokyo` calendar.
- `TimerStore` already stores an array of timers so multiple timers can be added without a migration. Keep new fields backward compatible with existing saved JSON (give them defaults or decode them as optional).
- Write user-facing text as Japanese string literals in `Text(...)` / `String(localized:)` so they land in the string catalog for future localization. Do not build sentences by concatenating strings.
- Use `.monospacedDigit()` on changing numbers so the layout does not jitter.
- Design direction is "refined simplicity": system font (SF Pro) in thin or light weights, monochrome, generous whitespace, no decorative color. Match what is already there.

## Roadmap

See the checklist in `README.md`. Widgets and Live Activities will need an App Group; when adding them, move `TimerStore` to `UserDefaults(suiteName:)` for that group and share the `Models/` code with the extension.

## Release notes

- Bundle ID: `com.trtrbz21.IkiisogiTimer` (still changeable until it is registered in App Store Connect).
- `DEVELOPMENT_TEAM` is empty until the owner joins the Apple Developer Program.
- Bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in the target build settings for each release.
