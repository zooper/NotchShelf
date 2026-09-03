import XCTest
@testable import NotchShelf

final class ShelfPresentationPolicyTests: XCTestCase {
    func testLaunchShowsShelfWhenPermissionIsMissing() {
        XCTAssertTrue(
            ShelfPresentationPolicy.shouldPresent(
                for: .applicationLaunch,
                permissionGranted: false
            )
        )
    }

    func testLaunchShowsShelfWhenPermissionAlreadyExists() {
        XCTAssertTrue(
            ShelfPresentationPolicy.shouldPresent(
                for: .applicationLaunch,
                permissionGranted: true
            )
        )
    }

    func testDockReopenAlwaysShowsReachableShelf() {
        XCTAssertTrue(
            ShelfPresentationPolicy.shouldPresent(
                for: .dockReopen,
                permissionGranted: false
            )
        )
        XCTAssertTrue(
            ShelfPresentationPolicy.shouldPresent(
                for: .dockReopen,
                permissionGranted: true
            )
        )
    }

    func testPermissionLossShowsRecoveryWindow() {
        XCTAssertTrue(
            ShelfPresentationPolicy.shouldPresent(
                for: .permissionChanged,
                permissionGranted: false
            )
        )
        XCTAssertFalse(
            ShelfPresentationPolicy.shouldPresent(
                for: .permissionChanged,
                permissionGranted: true
            )
        )
    }
}
