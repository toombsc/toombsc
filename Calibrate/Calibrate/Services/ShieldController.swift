import FamilyControls
import Foundation
import ManagedSettings

/// Applies and lifts the shield. Small on purpose — the monitor extension calls into this under
/// tight memory limits, so it stays free of anything but `ManagedSettings`.
enum ShieldController {
    private static var store: ManagedSettingsStore {
        ManagedSettingsStore(named: .calibrate)
    }

    /// Shields everything in the saved selection.
    ///
    /// Empty sets are written as nil rather than as empty collections: an empty (non-nil) shield set
    /// is a valid instruction meaning "shield nothing", but leaving the key set at all keeps the
    /// store dirty, and nil is the cleaner way to say a dimension is unused.
    static func apply(_ selection: FamilyActivitySelection) {
        let store = self.store
        store.shield.applications = selection.applicationTokens.isEmpty
            ? nil
            : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty
            ? nil
            : selection.webDomainTokens
    }

    static func clear() {
        store.clearAllSettings()
    }
}
