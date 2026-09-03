enum MenuBarOwnerFilter {
    /// System UI processes whose menu extras are standard macOS chrome rather
    /// than overflow candidates owned by a user-launched application.
    private static let excludedBundleIdentifiers: Set<String> = [
        "com.apple.controlcenter",
        "com.apple.systemuiserver",
        "com.apple.spotlight",
        "com.apple.siri",
        "com.apple.notificationcenterui",
        "com.apple.textinputmenuagent"
    ]

    static func shouldDiscover(bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier else { return true }
        return !excludedBundleIdentifiers.contains(bundleIdentifier.lowercased())
    }
}
