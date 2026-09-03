import XCTest
@testable import NotchShelf

final class MenuBarItemTests: XCTestCase {
    func testSearchMatchesLabelAppStatusAndHelpCaseInsensitively() {
        let item = makeItem(
            label: "Corporate VPN",
            app: "Secure Client",
            status: "Connected",
            help: "Open connection menu"
        )

        XCTAssertTrue(item.matches(searchText: "vpn"))
        XCTAssertTrue(item.matches(searchText: "SECURE"))
        XCTAssertTrue(item.matches(searchText: "connected"))
        XCTAssertTrue(item.matches(searchText: "connection"))
        XCTAssertFalse(item.matches(searchText: "calendar"))
    }

    func testBlankSearchMatchesEveryItem() {
        XCTAssertTrue(makeItem().matches(searchText: "  \n"))
    }

    func testPresentationChoosesFirstNonemptyUsefulLabel() {
        XCTAssertEqual(
            MenuBarItemPresentation.firstUsefulLabel(
                ["  ", "menu extra", "VPN status", "unused"],
                fallback: "Fallback"
            ),
            "VPN status"
        )
    }

    func testPresentationUsesFallbackWhenNoLabelIsUseful() {
        XCTAssertEqual(
            MenuBarItemPresentation.firstUsefulLabel([nil, ""], fallback: "Helper menu item"),
            "Helper menu item"
        )
    }

    func testStatusOmitsDuplicateLabel() {
        XCTAssertNil(
            MenuBarItemPresentation.conciseStatus(value: "Corporate VPN", mark: nil, label: "Corporate VPN")
        )
        XCTAssertEqual(
            MenuBarItemPresentation.conciseStatus(value: "Connected", mark: nil, label: "Corporate VPN"),
            "Connected"
        )
    }

    private func makeItem(
        label: String = "VPN",
        app: String = "Client",
        status: String? = nil,
        help: String? = nil
    ) -> MenuBarItem {
        MenuBarItem(
            id: UUID(),
            label: label,
            applicationName: app,
            bundleIdentifier: "example.client",
            applicationPath: nil,
            status: status,
            help: help,
            isEnabled: true,
            canInvoke: true
        )
    }
}
