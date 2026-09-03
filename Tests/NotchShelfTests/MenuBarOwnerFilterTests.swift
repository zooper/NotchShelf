import XCTest
@testable import NotchShelf

final class MenuBarOwnerFilterTests: XCTestCase {
    func testKnownSystemMenuOwnersAreExcluded() {
        XCTAssertFalse(MenuBarOwnerFilter.shouldDiscover(bundleIdentifier: "com.apple.controlcenter"))
        XCTAssertFalse(MenuBarOwnerFilter.shouldDiscover(bundleIdentifier: "com.apple.systemuiserver"))
        XCTAssertFalse(MenuBarOwnerFilter.shouldDiscover(bundleIdentifier: "com.apple.Spotlight"))
    }

    func testThirdPartyAndUnknownOwnersRemainDiscoverable() {
        XCTAssertTrue(MenuBarOwnerFilter.shouldDiscover(bundleIdentifier: "com.vendor.unfamiliar-helper"))
        XCTAssertTrue(MenuBarOwnerFilter.shouldDiscover(bundleIdentifier: nil))
    }

    func testOrdinaryAppleApplicationsAreNotBroadlyExcluded() {
        XCTAssertTrue(MenuBarOwnerFilter.shouldDiscover(bundleIdentifier: "com.apple.Safari"))
        XCTAssertTrue(MenuBarOwnerFilter.shouldDiscover(bundleIdentifier: "com.apple.some-new-app"))
    }
}
