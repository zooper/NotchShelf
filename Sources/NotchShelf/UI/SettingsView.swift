import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            Section("Interface") {
                Toggle(
                    "Show in Dock",
                    isOn: Binding(
                        get: { model.showsDockIcon },
                        set: { model.setDockIconEnabled($0) }
                    )
                )

                Toggle(
                    "Show menu bar shortcut",
                    isOn: Binding(
                        get: { model.showsMenuBarShortcut },
                        set: { model.setMenuBarShortcutEnabled($0) }
                    )
                )

                Text("The Dock icon is shown by default. The four-square shortcut opens the same shelf in a popover. NotchShelf keeps at least one of these ways to reopen the app available.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("Accessibility") {
                LabeledContent("Permission") {
                    Label(
                        model.permissionGranted ? "Allowed" : "Not allowed",
                        systemImage: model.permissionGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
                    )
                    .foregroundStyle(model.permissionGranted ? .green : .orange)
                }

                Text("NotchShelf uses the public macOS Accessibility API to discover menu bar controls and request their standard Press or Show Menu action.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                HStack {
                    Button("Request permission") {
                        model.requestPermission()
                    }
                    Button("Open Accessibility Settings") {
                        model.openAccessibilitySettings()
                    }
                }
            }

            Section("Discovery") {
                Text("Only controls that apps expose through Accessibility can appear. NotchShelf cannot reposition icons, reveal private menu bar data, or guarantee that every app can be invoked.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Button("Refresh now") {
                    model.refresh()
                }
                .disabled(!model.permissionGranted || model.isRefreshing)
            }
        }
        .formStyle(.grouped)
        .padding(8)
        .frame(width: 480, height: 430)
        .preferredColorScheme(.dark)
    }
}
