enum ShelfPresentationEvent: Sendable {
    case applicationLaunch
    case dockReopen
    case permissionChanged
}

enum ShelfPresentationPolicy {
    static func shouldPresent(
        for event: ShelfPresentationEvent,
        permissionGranted: Bool
    ) -> Bool {
        switch event {
        case .applicationLaunch, .dockReopen:
            return true
        case .permissionChanged:
            return !permissionGranted
        }
    }
}
