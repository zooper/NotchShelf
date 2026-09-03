# NotchShelf

NotchShelf is a small macOS utility for controls that become hard to reach when the display notch leaves too little menu bar space. Its compact shelf window opens on every launch and lists the menu bar items that running apps expose through the public macOS Accessibility API. The Dock icon is shown by default, and an optional four-square menu-bar shortcut opens the same shelf as a popover.

Selecting an available row asks the original control to perform its standard Accessibility `Press` or `Show Menu` action. NotchShelf does not copy another app's menu, inspect screen pixels, or use private frameworks.

## Requirements

- macOS 13 or later
- Xcode 15 or later with the macOS command-line tools selected
- Accessibility permission for the built `NotchShelf.app`

## Build and run

From the repository root:

```sh
./scripts/build-app.sh
open build/NotchShelf.app
```

The build script creates a release build by default and places the app at `build/NotchShelf.app`. It prefers an installed Developer ID, Apple Development, or Mac Developer code-signing identity so macOS sees the same app across rebuilds. For a faster development build, run `./scripts/build-app.sh debug`.

Set `NOTCHSHELF_CODESIGN_IDENTITY` to a certificate name or SHA-1 hash to choose a specific signing identity. If no stable identity exists, the script falls back to ad-hoc signing and prints a warning.

You can also open `Package.swift` in Xcode and run the `NotchShelf` executable scheme. The packaged `.app` is preferred for regular use because macOS Accessibility approval is tied to the app's identity and location.

Run the automated tests with:

```sh
swift test
```

## Accessibility permission

NotchShelf opens its shelf window on every launch. On first use, the window shows Accessibility onboarding; choose **Request Accessibility access**. macOS should open or prompt for:

**System Settings › Privacy & Security › Accessibility**

Enable NotchShelf there, then return to the panel. The permission state is checked automatically and discovery starts when access becomes available. If NotchShelf is absent from the list, use **Open System Settings**, navigate to **Privacy & Security › Accessibility**, add `build/NotchShelf.app` with the `+` button, and enable it.

After setup, use the shelf window normally or close and reopen it from the Dock. Press **Command-O** while NotchShelf is active for the same action. Both **Show in Dock** and the four-square menu-bar shortcut are enabled by default and can be changed under **Settings › Interface**. NotchShelf keeps at least one of those reopen routes enabled: hiding the Dock preserves the menu-bar shortcut, and hiding the last menu-bar shortcut restores the Dock. You can also relaunch the app from Finder or Spotlight. Closing the shelf window does not quit the app. If Accessibility permission is later removed, NotchShelf opens the permission window again automatically even when running as a Dock-less accessory app.

The permission is required because NotchShelf asks running apps for their Accessibility element trees and invokes actions on selected menu bar elements. It does not install an event tap, capture keyboard input, record the screen, or send data over the network.

Accessibility approval is tied to the app's code requirement. A purely ad-hoc signature uses a build-specific code hash, so macOS can retain an enabled-looking NotchShelf row for an older build while rejecting the current executable. The build script avoids that loop when a stable local certificate is available. If it warns that it used ad-hoc signing, approval may need to be renewed after rebuilding. A Developer ID signature is recommended for a distributed build.

## How discovery and invocation work

1. NotchShelf enumerates currently running applications and UI agents, conservatively omitting only known macOS menu-bar owners such as Control Center, SystemUIServer, Spotlight, Siri, Notification Center, and the text-input menu agent.
2. For each process, it creates a public `AXUIElement` application reference and requests `kAXExtrasMenuBarAttribute`.
3. It walks that exposed extras hierarchy looking for `AXMenuBarItem` elements.
4. Labels come from the first useful Accessibility title, description, or help string. Status comes from an exposed value or menu-item mark. The running application's icon is used when available.
5. On selection, NotchShelf uses `AXUIElementPerformAction` with `AXPress` or `AXShowMenu`, choosing only an action the element says it supports.

Accessibility objects stay on a dedicated serial queue. The panel receives only display metadata and opaque item identifiers.

## Known macOS limitations

Public macOS APIs do not provide a complete overflow menu or let one app relocate another app's status item. The MVP therefore has deliberate limits:

- Only items that a running app exposes through `kAXExtrasMenuBarAttribute` can be discovered. Some third-party utilities expose no status item, no label, or an incomplete Accessibility tree.
- Standard macOS-owned menu-bar controls such as the clock, battery, Control Center, Spotlight, and similar system chrome are intentionally excluded. Filtering uses a short explicit owner-bundle list rather than labels, so unfamiliar third-party items remain eligible.
- A discovered item may expose metadata but neither `AXPress` nor `AXShowMenu`. NotchShelf keeps it visible as **View only** and explains that it cannot be opened automatically.
- An app can refuse an Accessibility action, stop responding, quit, or replace its item between refresh and selection. NotchShelf reports these cases and asks for a refresh where appropriate.
- The list is a snapshot. Open the panel or use Refresh after starting, quitting, or reconfiguring menu bar apps.
- macOS decides the physical ordering and visibility of all status items. No supported API can guarantee that NotchShelf's optional shortcut remains visible when the menu bar is exceptionally crowded. Keep **Show in Dock** enabled when Dock-based recovery is preferred; it is the default.
- System controls and Apple menu extras may be owned by processes such as Control Center and can expose less information than third-party apps.
- NotchShelf does not use private window-server APIs, simulate mouse clicks at screen coordinates, hide other apps, or temporarily change display resolution to work around these limits.

These constraints are why the interface distinguishes discovered, disabled, and view-only controls instead of promising universal access.

## Project layout

- `Sources/NotchShelf/Accessibility` — permission, discovery, and supported action invocation
- `Sources/NotchShelf/Model` — observable app state and searchable item metadata
- `Sources/NotchShelf/UI` — status panel and settings interface
- `Resources/Info.plist` — local app-bundle metadata
- `scripts/build-app.sh` — reproducible local `.app` packaging
- `scripts/generate-app-icon.swift` — multi-resolution four-square-and-shelf application icon
- `Tests/NotchShelfTests` — search and presentation behavior tests
