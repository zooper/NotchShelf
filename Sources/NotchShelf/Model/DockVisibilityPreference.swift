import Foundation

struct DockVisibilityPreference {
    private static let key = "showsDockIcon"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isEnabled: Bool {
        get {
            guard defaults.object(forKey: Self.key) != nil else { return true }
            return defaults.bool(forKey: Self.key)
        }
        set {
            defaults.set(newValue, forKey: Self.key)
        }
    }
}

enum ReachabilitySurface {
    case dock
    case menuBar
}

struct ReachabilityConfiguration: Equatable {
    let showsDockIcon: Bool
    let showsMenuBarShortcut: Bool

    static func normalized(
        showsDockIcon: Bool,
        showsMenuBarShortcut: Bool,
        preferredFallback: ReachabilitySurface
    ) -> ReachabilityConfiguration {
        guard !showsDockIcon && !showsMenuBarShortcut else {
            return ReachabilityConfiguration(
                showsDockIcon: showsDockIcon,
                showsMenuBarShortcut: showsMenuBarShortcut
            )
        }

        switch preferredFallback {
        case .dock:
            return ReachabilityConfiguration(
                showsDockIcon: true,
                showsMenuBarShortcut: false
            )
        case .menuBar:
            return ReachabilityConfiguration(
                showsDockIcon: false,
                showsMenuBarShortcut: true
            )
        }
    }
}
