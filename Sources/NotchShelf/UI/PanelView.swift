import AppKit
import SwiftUI

struct PanelView: View {
    @ObservedObject var model: AppModel
    let dismiss: @MainActor @Sendable () -> Void
    let showSettings: @MainActor @Sendable () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            if !model.permissionGranted {
                permissionOnboarding
            } else {
                browser
            }
        }
        .frame(width: 388, height: 510)
        .background(Color(nsColor: .windowBackgroundColor))
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .accessibilityHidden(true)

            Text("NotchShelf")
                .font(.system(size: 15, weight: .semibold))

            Spacer()

            if model.permissionGranted {
                Button {
                    model.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .disabled(model.isRefreshing)
                .help("Refresh menu bar items")
                .accessibilityLabel("Refresh menu bar items")
            }

            Menu {
                Button("Settings…", action: showSettings)
                Button("About NotchShelf") {
                    NSApp.orderFrontStandardAboutPanel(options: [
                        .applicationName: "NotchShelf",
                        .applicationVersion: appVersion,
                        .credits: NSAttributedString(
                            string: "A small, public-API-only shelf for menu bar controls hidden by a display notch."
                        )
                    ])
                    NSApp.activate(ignoringOtherApps: true)
                }
                Divider()
                Button("Quit NotchShelf") {
                    NSApp.terminate(nil)
                }
            } label: {
                Image(systemName: "gearshape")
                    .frame(width: 24, height: 24)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .frame(width: 28)
            .help("Settings and about")
            .accessibilityLabel("Settings and about")
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var permissionOnboarding: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer(minLength: 20)

            Image(systemName: "hand.raised.fill")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text("See the controls macOS makes available")
                    .font(.system(size: 19, weight: .semibold))

                Text("NotchShelf needs Accessibility access to find menu bar items and ask them to open. It does not read keystrokes or screen contents.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                Button("Request Accessibility access") {
                    model.requestPermission()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)

                Button("Open System Settings") {
                    model.openAccessibilitySettings()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }

            Text("After enabling NotchShelf in Privacy & Security › Accessibility, return here. Discovery starts automatically.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 18)
    }

    private var browser: some View {
        VStack(spacing: 0) {
            searchField

            if let notice = model.notice {
                noticeBanner(notice)
            }

            Group {
                if model.isRefreshing && model.items.isEmpty {
                    loadingState
                } else if model.filteredItems.isEmpty {
                    emptyState
                } else {
                    itemList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            footer
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField("Search menu bar items", text: $model.searchText)
                .textFieldStyle(.plain)

            if !model.searchText.isEmpty {
                Button {
                    model.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 7))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var itemList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(model.filteredItems) { item in
                    Button {
                        model.invoke(item, onSuccess: dismiss)
                    } label: {
                        MenuBarItemRow(item: item)
                    }
                    .buttonStyle(MenuBarItemButtonStyle())
                    .help(item.canInvoke
                          ? "Open \(item.label)"
                          : "This app does not expose an action macOS can perform")
                    .accessibilityHint(item.canInvoke
                                       ? "Attempts to open the original menu bar control"
                                       : "The original app does not expose an invokable action")
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
    }

    private var loadingState: some View {
        VStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text("Looking for menu bar items…")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: model.searchText.isEmpty ? "menubar.rectangle" : "magnifyingglass")
                .font(.system(size: 27, weight: .light))
                .foregroundStyle(.tertiary)

            Text(model.searchText.isEmpty ? "No accessible items found" : "No matching items")
                .font(.system(size: 13, weight: .medium))

            Text(model.searchText.isEmpty
                 ? "Some apps do not expose their menu bar controls to Accessibility. Try Refresh after opening the app you need."
                 : "Try an app name, control label, or status.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 270)

            if model.searchText.isEmpty {
                Button("Refresh") {
                    model.refresh()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Text("\(model.items.count) item\(model.items.count == 1 ? "" : "s")")
            if model.applicationsScanned > 0 {
                Text("from \(model.applicationsScanned) running apps")
            }
            Spacer()
            if model.isRefreshing {
                ProgressView()
                    .controlSize(.mini)
            }
        }
        .font(.system(size: 10))
        .foregroundStyle(.tertiary)
        .padding(.horizontal, 14)
        .frame(height: 28)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private func noticeBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.system(size: 11))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button {
                model.notice = nil
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss message")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.yellow.opacity(0.08))
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
    }
}

private struct MenuBarItemRow: View {
    let item: MenuBarItem

    var body: some View {
        HStack(spacing: 11) {
            applicationIcon

            VStack(alignment: .leading, spacing: 3) {
                Text(item.label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(item.isEnabled ? .primary : .secondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(item.applicationName)
                        .lineLimit(1)

                    if let status = item.status {
                        Text(status)
                            .lineLimit(1)
                    }

                    if !item.canInvoke {
                        Label("View only", systemImage: "eye")
                            .lineLimit(1)
                    }
                }
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: item.canInvoke ? "chevron.right" : "lock")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 8)
        .frame(height: 50)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var applicationIcon: some View {
        if let path = item.applicationPath {
            Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                .resizable()
                .scaledToFit()
                .frame(width: 26, height: 26)
                .accessibilityHidden(true)
        } else {
            Image(systemName: "app.dashed")
                .font(.system(size: 19))
                .foregroundStyle(.secondary)
                .frame(width: 26, height: 26)
                .accessibilityHidden(true)
        }
    }
}

private struct MenuBarItemButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed
                    ? Color.accentColor.opacity(0.22)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: 7)
            )
    }
}
