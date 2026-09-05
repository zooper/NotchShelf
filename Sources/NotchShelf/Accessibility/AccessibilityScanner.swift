import ApplicationServices
import Foundation

struct ProcessCandidate: Sendable {
    let processIdentifier: pid_t
    let name: String
    let bundleIdentifier: String?
    let applicationPath: String?
}

struct ScanResult: Sendable {
    let items: [MenuBarItem]
    let applicationsScanned: Int
    let inaccessibleApplications: Int
}

enum InvocationResult: Sendable, Equatable {
    case succeeded
    case failed(String)
}

enum AccessibilityActionSelection {
    static func preferredAction(in actions: [String]) -> String? {
        [kAXPressAction as String, kAXShowMenuAction as String]
            .first(where: actions.contains)
    }
}

private struct InvocationTarget {
    let element: AXUIElement
    let action: String?
}

/// AXUIElement is a Core Foundation reference without Sendable conformance.
/// All element access and storage is isolated to this scanner's serial queue.
final class AccessibilityScanner: @unchecked Sendable {
    private let queue = DispatchQueue(label: "io.jonsson.NotchShelf.accessibility")
    private var targetsByID: [UUID: InvocationTarget] = [:]

    func discover(in candidates: [ProcessCandidate]) async -> ScanResult {
        await withCheckedContinuation { continuation in
            queue.async { [self] in
                continuation.resume(returning: scan(candidates))
            }
        }
    }

    func invoke(itemID: UUID) async -> InvocationResult {
        await withCheckedContinuation { continuation in
            queue.async { [self] in
                continuation.resume(returning: performInvocation(itemID: itemID))
            }
        }
    }

    private func scan(_ candidates: [ProcessCandidate]) -> ScanResult {
        guard AXIsProcessTrusted() else {
            targetsByID = [:]
            return ScanResult(items: [], applicationsScanned: 0, inaccessibleApplications: 0)
        }

        var discovered: [MenuBarItem] = []
        var newTargets: [UUID: InvocationTarget] = [:]
        var inaccessibleCount = 0

        for candidate in candidates {
            let application = AXUIElementCreateApplication(candidate.processIdentifier)
            var menuBarValue: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(
                application,
                kAXExtrasMenuBarAttribute as CFString,
                &menuBarValue
            )

            guard result == .success,
                  let menuBarValue,
                  CFGetTypeID(menuBarValue) == AXUIElementGetTypeID() else {
                if result == .cannotComplete || result == .apiDisabled || result == .notImplemented {
                    inaccessibleCount += 1
                }
                continue
            }
            let menuBar = unsafeDowncast(menuBarValue, to: AXUIElement.self)

            let menuItems = descendants(of: menuBar)
                .filter { stringAttribute($0, kAXRoleAttribute) == (kAXMenuBarItemRole as String) }

            for element in menuItems {
                let id = UUID()
                let title = stringAttribute(element, kAXTitleAttribute)
                let description = stringAttribute(element, kAXDescriptionAttribute)
                let help = stringAttribute(element, kAXHelpAttribute)
                let value = stringAttribute(element, kAXValueAttribute)
                let mark = stringAttribute(element, kAXMenuItemMarkCharAttribute)
                let enabled = boolAttribute(element, kAXEnabledAttribute) ?? true
                let actions = actionNames(for: element)
                let action = AccessibilityActionSelection.preferredAction(in: actions)
                let label = MenuBarItemPresentation.firstUsefulLabel(
                    [title, description, help],
                    fallback: "\(candidate.name) menu item"
                )

                let item = MenuBarItem(
                    id: id,
                    label: label,
                    applicationName: candidate.name,
                    bundleIdentifier: candidate.bundleIdentifier,
                    applicationPath: candidate.applicationPath,
                    status: MenuBarItemPresentation.conciseStatus(
                        value: value,
                        mark: mark,
                        label: label
                    ),
                    help: help == label ? nil : help,
                    isEnabled: enabled,
                    canInvoke: action != nil
                )

                discovered.append(item)
                newTargets[id] = InvocationTarget(element: element, action: action)
            }
        }

        targetsByID = newTargets
        return ScanResult(
            items: deduplicate(discovered),
            applicationsScanned: candidates.count,
            inaccessibleApplications: inaccessibleCount
        )
    }

    private func performInvocation(itemID: UUID) -> InvocationResult {
        guard let target = targetsByID[itemID] else {
            return .failed("This item changed. Refresh the list and try again.")
        }

        guard let action = target.action else {
            return .failed("macOS exposes this item, but not an action NotchShelf can perform.")
        }

        let result = AXUIElementPerformAction(target.element, action as CFString)
        switch result {
        case .success:
            return .succeeded
        case .cannotComplete:
            return .failed("The app did not respond. Make sure it is running and try again.")
        case .actionUnsupported:
            return .failed("This app does not allow its menu item to be opened through Accessibility.")
        case .invalidUIElement:
            return .failed("This item is no longer available. Refresh the list and try again.")
        case .apiDisabled:
            return .failed("Accessibility access is no longer available. Check System Settings.")
        default:
            return .failed("macOS could not open this menu item (error \(result.rawValue)).")
        }
    }

    private func descendants(of root: AXUIElement) -> [AXUIElement] {
        var result: [AXUIElement] = []
        var pending: [(element: AXUIElement, depth: Int)] = [(root, 0)]
        var visited = 0

        while let current = pending.popLast(), visited < 500 {
            visited += 1
            result.append(current.element)
            guard current.depth < 6 else { continue }
            for child in children(of: current.element) {
                pending.append((child, current.depth + 1))
            }
        }

        return result
    }

    private func children(of element: AXUIElement) -> [AXUIElement] {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXChildrenAttribute as CFString,
            &value
        ) == .success else { return [] }
        return value as? [AXUIElement] ?? []
    }

    private func stringAttribute(_ element: AXUIElement, _ attribute: String) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element,
            attribute as CFString,
            &value
        ) == .success else { return nil }

        if let string = value as? String { return string }
        if let number = value as? NSNumber { return number.stringValue }
        return nil
    }

    private func boolAttribute(_ element: AXUIElement, _ attribute: String) -> Bool? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element,
            attribute as CFString,
            &value
        ) == .success else { return nil }
        return (value as? NSNumber)?.boolValue
    }

    private func actionNames(for element: AXUIElement) -> [String] {
        var actions: CFArray?
        guard AXUIElementCopyActionNames(element, &actions) == .success else { return [] }
        return actions as? [String] ?? []
    }

    private func deduplicate(_ items: [MenuBarItem]) -> [MenuBarItem] {
        var keys = Set<String>()
        return items
            .sorted {
                let appComparison = $0.applicationName.localizedCaseInsensitiveCompare($1.applicationName)
                if appComparison == .orderedSame {
                    return $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending
                }
                return appComparison == .orderedAscending
            }
            .filter { item in
                let key = [
                    item.bundleIdentifier ?? item.applicationName,
                    item.label,
                    item.status ?? ""
                ].joined(separator: "|")
                return keys.insert(key).inserted
            }
    }
}
