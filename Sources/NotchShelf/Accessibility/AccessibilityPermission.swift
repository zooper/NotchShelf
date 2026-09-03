import AppKit
@preconcurrency import ApplicationServices

enum AccessibilityPermission {
    static var isGranted: Bool {
        AXIsProcessTrusted()
    }

    @discardableResult
    static func request() -> Bool {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func openSystemSettings() {
        guard let url = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: "com.apple.systempreferences"
        ) else { return }

        NSWorkspace.shared.openApplication(
            at: url,
            configuration: NSWorkspace.OpenConfiguration()
        )
    }
}
