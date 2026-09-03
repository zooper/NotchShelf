import Foundation

struct MenuBarItem: Identifiable, Hashable, Sendable {
    let id: UUID
    let label: String
    let applicationName: String
    let bundleIdentifier: String?
    let applicationPath: String?
    let status: String?
    let help: String?
    let isEnabled: Bool
    let canInvoke: Bool

    func matches(searchText: String) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }

        return [label, applicationName, status, help]
            .compactMap { $0 }
            .contains { $0.localizedCaseInsensitiveContains(query) }
    }
}

enum MenuBarItemPresentation {
    static func firstUsefulLabel(_ candidates: [String?], fallback: String) -> String {
        candidates
            .compactMap { value -> String? in
                guard let value else { return nil }
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty, trimmed != "menu extra" else { return nil }
                return trimmed
            }
            .first ?? fallback
    }

    static func conciseStatus(value: String?, mark: String?, label: String) -> String? {
        let candidate = [value, mark]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty && $0 != label }

        return candidate
    }
}
