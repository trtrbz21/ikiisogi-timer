import SwiftUI

/// Keys for app-wide preferences stored with `@AppStorage`.
enum SettingsKey {
    static let displayUnit = "settings.displayUnit"
    static let keepScreenOn = "settings.keepScreenOn"
    static let appearance = "settings.appearance"
}

/// Pages hosted with GitHub Pages from `docs/` (Japanese) and `docs/en/` (English).
enum AppLinks {
    private static var base: String {
        // Match the language the app is actually shown in (respects the per-app language setting).
        let isJapanese = Bundle.main.preferredLocalizations.first == "ja"
        return isJapanese ? "https://trtrbz21.github.io/ikiisogi-timer/" : "https://trtrbz21.github.io/ikiisogi-timer/en/"
    }

    static var support: URL { URL(string: base)! }
    static var privacyPolicy: URL { URL(string: base + "privacy.html")! }
}

extension Color {
    /// Deep navy used by the "濃紺" theme in the app and widgets (#0E1A33).
    static let navy = Color(red: 14 / 255, green: 26 / 255, blue: 51 / 255)
}

enum Appearance: String, CaseIterable {
    case system
    case light
    case dark
    case navy

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark, .navy: .dark
        }
    }

    /// A background that replaces the system one. `nil` keeps the standard background.
    var backgroundColor: Color? {
        self == .navy ? .navy : nil
    }

    var label: LocalizedStringKey {
        switch self {
        case .system: "システムに合わせる"
        case .light: "ライト"
        case .dark: "ダーク"
        case .navy: "濃紺"
        }
    }
}

extension DisplayUnit {
    /// Used in pickers ("Minutes" in English).
    var label: LocalizedStringKey {
        switch self {
        case .minutes: "分"
        case .seconds: "秒"
        }
    }

    /// Used next to the big number ("min" in English).
    var shortLabel: LocalizedStringResource {
        switch self {
        case .minutes: LocalizedStringResource("unit.minutes.short", defaultValue: "分")
        case .seconds: LocalizedStringResource("unit.seconds.short", defaultValue: "秒")
        }
    }
}
