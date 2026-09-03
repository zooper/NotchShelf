import Foundation

struct MenuBarShortcutPreference {
    private static let key = "showsMenuBarShortcut"

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
