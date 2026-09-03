import AppKit
import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var permissionGranted = AccessibilityPermission.isGranted
    @Published private(set) var items: [MenuBarItem] = []
    @Published private(set) var isRefreshing = false
    @Published private(set) var applicationsScanned = 0
    @Published private(set) var inaccessibleApplications = 0
    @Published var searchText = ""
    @Published var notice: String?
    @Published private(set) var showsMenuBarShortcut: Bool
    @Published private(set) var showsDockIcon: Bool

    private let scanner = AccessibilityScanner()
    private var menuBarShortcutPreference: MenuBarShortcutPreference
    private var dockVisibilityPreference: DockVisibilityPreference
    private var permissionTimer: Timer?
    private var hasPerformedInitialScan = false

    var filteredItems: [MenuBarItem] {
        items.filter { $0.matches(searchText: searchText) }
    }

    init(
        menuBarShortcutPreference: MenuBarShortcutPreference = MenuBarShortcutPreference(),
        dockVisibilityPreference: DockVisibilityPreference = DockVisibilityPreference()
    ) {
        self.menuBarShortcutPreference = menuBarShortcutPreference
        self.dockVisibilityPreference = dockVisibilityPreference
        let reachability = ReachabilityConfiguration.normalized(
            showsDockIcon: dockVisibilityPreference.isEnabled,
            showsMenuBarShortcut: menuBarShortcutPreference.isEnabled,
            preferredFallback: .dock
        )
        showsMenuBarShortcut = reachability.showsMenuBarShortcut
        showsDockIcon = reachability.showsDockIcon
        self.menuBarShortcutPreference.isEnabled = reachability.showsMenuBarShortcut
        self.dockVisibilityPreference.isEnabled = reachability.showsDockIcon
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkPermission()
            }
        }
    }

    isolated deinit {
        permissionTimer?.invalidate()
    }

    func panelDidOpen() {
        checkPermission()
        if permissionGranted && !hasPerformedInitialScan {
            refresh()
        }
    }

    func requestPermission() {
        _ = AccessibilityPermission.request()
        checkPermission()
    }

    func openAccessibilitySettings() {
        AccessibilityPermission.openSystemSettings()
    }

    func setMenuBarShortcutEnabled(_ isEnabled: Bool) {
        applyReachabilityConfiguration(
            ReachabilityConfiguration.normalized(
                showsDockIcon: showsDockIcon,
                showsMenuBarShortcut: isEnabled,
                preferredFallback: .dock
            )
        )
    }

    func setDockIconEnabled(_ isEnabled: Bool) {
        applyReachabilityConfiguration(
            ReachabilityConfiguration.normalized(
                showsDockIcon: isEnabled,
                showsMenuBarShortcut: showsMenuBarShortcut,
                preferredFallback: .menuBar
            )
        )
    }

    func refresh() {
        guard permissionGranted, !isRefreshing else { return }
        isRefreshing = true
        notice = nil

        let candidates = NSWorkspace.shared.runningApplications.compactMap { app -> ProcessCandidate? in
            guard app.processIdentifier != ProcessInfo.processInfo.processIdentifier,
                  !app.isTerminated,
                  MenuBarOwnerFilter.shouldDiscover(bundleIdentifier: app.bundleIdentifier) else {
                return nil
            }

            return ProcessCandidate(
                processIdentifier: app.processIdentifier,
                name: app.localizedName ?? app.bundleIdentifier ?? "Unknown app",
                bundleIdentifier: app.bundleIdentifier,
                applicationPath: app.bundleURL?.path
            )
        }

        Task { [scanner] in
            let result = await scanner.discover(in: candidates)
            guard !Task.isCancelled else { return }
            items = result.items
            applicationsScanned = result.applicationsScanned
            inaccessibleApplications = result.inaccessibleApplications
            isRefreshing = false
            hasPerformedInitialScan = true
        }
    }

    func invoke(_ item: MenuBarItem, onSuccess: @escaping @MainActor () -> Void) {
        guard item.isEnabled else {
            notice = "\(item.label) is currently disabled."
            return
        }
        guard item.canInvoke else {
            notice = "macOS exposes \(item.label), but the app does not provide an action NotchShelf can perform."
            return
        }

        notice = nil
        Task { [scanner] in
            switch await scanner.invoke(itemID: item.id) {
            case .succeeded:
                onSuccess()
            case .failed(let message):
                notice = message
            }
        }
    }

    private func checkPermission() {
        let currentlyGranted = AccessibilityPermission.isGranted
        guard currentlyGranted != permissionGranted else { return }
        permissionGranted = currentlyGranted

        if currentlyGranted {
            notice = nil
            refresh()
        } else {
            items = []
            hasPerformedInitialScan = false
        }
    }

    private func applyReachabilityConfiguration(_ configuration: ReachabilityConfiguration) {
        showsDockIcon = configuration.showsDockIcon
        showsMenuBarShortcut = configuration.showsMenuBarShortcut
        dockVisibilityPreference.isEnabled = configuration.showsDockIcon
        menuBarShortcutPreference.isEnabled = configuration.showsMenuBarShortcut
    }
}
