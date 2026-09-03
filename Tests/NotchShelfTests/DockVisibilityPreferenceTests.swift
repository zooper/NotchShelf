import XCTest
@testable import NotchShelf

final class DockVisibilityPreferenceTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "DockVisibilityPreferenceTests")
        defaults.removePersistentDomain(forName: "DockVisibilityPreferenceTests")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "DockVisibilityPreferenceTests")
        defaults = nil
        super.tearDown()
    }

    func testDockIconDefaultsToVisible() {
        XCTAssertTrue(DockVisibilityPreference(defaults: defaults).isEnabled)
    }

    func testDockIconChoicePersists() {
        var preference = DockVisibilityPreference(defaults: defaults)
        preference.isEnabled = false
        XCTAssertFalse(DockVisibilityPreference(defaults: defaults).isEnabled)

        preference.isEnabled = true
        XCTAssertTrue(DockVisibilityPreference(defaults: defaults).isEnabled)
    }

    func testHidingLastDockSurfaceKeepsMenuBarShortcut() {
        let configuration = ReachabilityConfiguration.normalized(
            showsDockIcon: false,
            showsMenuBarShortcut: false,
            preferredFallback: .menuBar
        )

        XCTAssertFalse(configuration.showsDockIcon)
        XCTAssertTrue(configuration.showsMenuBarShortcut)
    }

    func testHidingLastMenuBarSurfaceRestoresDock() {
        let configuration = ReachabilityConfiguration.normalized(
            showsDockIcon: false,
            showsMenuBarShortcut: false,
            preferredFallback: .dock
        )

        XCTAssertTrue(configuration.showsDockIcon)
        XCTAssertFalse(configuration.showsMenuBarShortcut)
    }
}
