import XCTest
@testable import NotchShelf

final class MenuBarShortcutPreferenceTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "MenuBarShortcutPreferenceTests")
        defaults.removePersistentDomain(forName: "MenuBarShortcutPreferenceTests")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "MenuBarShortcutPreferenceTests")
        defaults = nil
        super.tearDown()
    }

    func testMenuBarShortcutDefaultsToVisible() {
        let preference = MenuBarShortcutPreference(defaults: defaults)
        XCTAssertTrue(preference.isEnabled)
    }

    func testMenuBarShortcutChoicePersists() {
        var preference = MenuBarShortcutPreference(defaults: defaults)
        preference.isEnabled = false

        XCTAssertFalse(MenuBarShortcutPreference(defaults: defaults).isEnabled)

        preference.isEnabled = true
        XCTAssertTrue(MenuBarShortcutPreference(defaults: defaults).isEnabled)
    }
}
