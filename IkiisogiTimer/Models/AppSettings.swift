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

enum Appearance: String, CaseIterable {
    case system
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var label: LocalizedStringKey {
        switch self {
        case .system: "システムに合わせる"
        case .light: "ライト"
        case .dark: "ダーク"
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
