import SwiftUI

/// Keys for app-wide preferences stored with `@AppStorage`.
enum SettingsKey {
    static let displayUnit = "settings.displayUnit"
    static let keepScreenOn = "settings.keepScreenOn"
    static let appearance = "settings.appearance"
}

/// Pages hosted with GitHub Pages from `docs/`.
enum AppLinks {
    static let support = URL(string: "https://trtrbz21.github.io/ikiisogi-timer/")!
    static let privacyPolicy = URL(string: "https://trtrbz21.github.io/ikiisogi-timer/privacy.html")!
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
    var label: LocalizedStringKey {
        switch self {
        case .minutes: "分"
        case .seconds: "秒"
        }
    }
}
