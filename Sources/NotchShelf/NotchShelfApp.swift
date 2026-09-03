import AppKit
import Combine
import SwiftUI

@main
struct NotchShelfApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(model: appDelegate.model)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open NotchShelf") {
                    appDelegate.showShelfWindow()
                }
                .keyboardShortcut("o")
            }
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    private var statusBarController: StatusBarController?
    private var shelfWindowController: NSWindowController?
    private var settingsWindowController: NSWindowController?
    private var permissionCancellable: AnyCancellable?
    private var menuBarShortcutCancellable: AnyCancellable?
    private var dockIconCancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        dockIconCancellable = model.$showsDockIcon
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                self?.setDockIconEnabled(isEnabled)
            }

        menuBarShortcutCancellable = model.$showsMenuBarShortcut
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                self?.setMenuBarShortcutEnabled(isEnabled)
            }

        permissionCancellable = model.$permissionGranted
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] permissionGranted in
                guard ShelfPresentationPolicy.shouldPresent(
                    for: .permissionChanged,
                    permissionGranted: permissionGranted
                ) else { return }
                self?.showShelfWindow()
            }

        if ShelfPresentationPolicy.shouldPresent(
            for: .applicationLaunch,
            permissionGranted: model.permissionGranted
        ) {
            showShelfWindow()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        if ShelfPresentationPolicy.shouldPresent(
            for: .dockReopen,
            permissionGranted: model.permissionGranted
        ) {
            showShelfWindow()
        }
        return true
    }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        let openItem = NSMenuItem(
            title: "Open NotchShelf",
            action: #selector(openShelfFromDockMenu),
            keyEquivalent: ""
        )
        openItem.target = self
        menu.addItem(openItem)
        return menu
    }

    @objc private func openShelfFromDockMenu() {
        showShelfWindow()
    }

    private func setMenuBarShortcutEnabled(_ isEnabled: Bool) {
        if isEnabled {
            guard statusBarController == nil else { return }
            statusBarController = StatusBarController(
                model: model,
                showSettings: { [weak self] in self?.showSettings() }
            )
        } else {
            statusBarController?.removeFromStatusBar()
            statusBarController = nil
        }
    }

    private func setDockIconEnabled(_ isEnabled: Bool) {
        NSApp.setActivationPolicy(isEnabled ? .regular : .accessory)
    }

    func showShelfWindow() {
        statusBarController?.closePopover()

        if shelfWindowController == nil {
            let content = PanelView(
                model: model,
                dismiss: { [weak self] in
                    self?.shelfWindowController?.window?.orderOut(nil)
                },
                showSettings: { [weak self] in self?.showSettings() }
            )
            let hostingController = NSHostingController(rootView: content)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "NotchShelf"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.tabbingMode = .disallowed
            window.center()
            shelfWindowController = NSWindowController(window: window)
        }

        model.panelDidOpen()
        shelfWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        shelfWindowController?.window?.makeKeyAndOrderFront(nil)
    }

    private func showSettings() {
        statusBarController?.closePopover()

        if settingsWindowController == nil {
            let content = SettingsView(model: model)
            let hostingController = NSHostingController(rootView: content)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "NotchShelf Settings"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindowController = NSWindowController(window: window)
        }

        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
    }
}

@MainActor
final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let model: AppModel

    init(model: AppModel, showSettings: @escaping @MainActor @Sendable () -> Void) {
        self.model = model
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = statusItem.button {
            let configuration = NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
            button.image = NSImage(systemSymbolName: "square.grid.2x2.fill", accessibilityDescription: "NotchShelf")?
                .withSymbolConfiguration(configuration)
            button.image?.isTemplate = true
            button.toolTip = "NotchShelf — hidden menu bar items"
            button.target = self
            button.action = #selector(togglePopover(_:))
        }

        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 388, height: 510)
        popover.contentViewController = NSHostingController(
            rootView: PanelView(
                model: model,
                dismiss: { [weak popover] in popover?.performClose(nil) },
                showSettings: showSettings
            )
        )
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            model.panelDidOpen()
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    func closePopover() {
        popover.performClose(nil)
    }

    func removeFromStatusBar() {
        popover.performClose(nil)
        statusItem.button?.target = nil
        statusItem.button?.action = nil
        NSStatusBar.system.removeStatusItem(statusItem)
    }
}
