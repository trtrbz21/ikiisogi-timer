import SwiftUI

/// Keys for app-wide preferences stored with `@AppStorage`.
enum SettingsKey {
    static let displayUnit = "settings.displayUnit"
    static let keepScreenOn = "settings.keepScreenOn"
    static let appearance = "settings.appearance"
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
