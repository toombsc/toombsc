import FamilyControls
import Foundation

/// Everything the app and its two extensions need to agree on, kept in the shared App Group
/// container. The extensions run in their own processes and can't reach the app's own defaults, so
/// this is the only channel between them.
///
/// If `UserDefaults(suiteName:)` returns nil the App Group is misconfigured in the project settings.
/// We fall back to `.standard` so the app still runs, but the extensions will silently stop
/// agreeing with it — `isAppGroupAvailable` surfaces that in Settings rather than letting it become
/// a baffling bug.
enum SharedStore {
    static let appGroupID = "group.com.toombsc.calibrate"

    static var isAppGroupAvailable: Bool {
        UserDefaults(suiteName: appGroupID) != nil
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    private enum Key {
        static let selection = "calibrate.selection"
        static let schedules = "calibrate.schedules"
        static let manualPauseEnd = "calibrate.manualPauseEnd"
        static let activeScheduleIDs = "calibrate.activeScheduleIDs"
    }

    // MARK: - App selection

    /// The apps, categories, and web domains chosen in the `FamilyActivityPicker`.
    ///
    /// These are opaque tokens, not bundle IDs — they're only meaningful to `ManagedSettings`, and
    /// they're the reason no bundle IDs appear anywhere in this project.
    static var selection: FamilyActivitySelection {
        get {
            guard let data = defaults.data(forKey: Key.selection),
                  let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            else { return FamilyActivitySelection() }
            return decoded
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            defaults.set(data, forKey: Key.selection)
        }
    }

    static var hasSelection: Bool {
        let current = selection
        return !current.applicationTokens.isEmpty
            || !current.categoryTokens.isEmpty
            || !current.webDomainTokens.isEmpty
    }

    // MARK: - Schedules

    static var schedules: [PauseSchedule] {
        get {
            guard let data = defaults.data(forKey: Key.schedules),
                  let decoded = try? JSONDecoder().decode([PauseSchedule].self, from: data)
            else { return [] }
            return decoded
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            defaults.set(data, forKey: Key.schedules)
        }
    }

    // MARK: - Live pause state

    /// When the current manual pause lifts, or nil if none is running.
    ///
    /// This is the backstop for the case the whole design turns on: if the monitor extension never
    /// fires, `PauseCoordinator` compares this against the clock on next launch and clears a shield
    /// that has outlived its timer.
    static var manualPauseEnd: Date? {
        get {
            let stored = defaults.double(forKey: Key.manualPauseEnd)
            guard stored > 0 else { return nil }
            return Date(timeIntervalSince1970: stored)
        }
        set {
            if let newValue {
                defaults.set(newValue.timeIntervalSince1970, forKey: Key.manualPauseEnd)
            } else {
                defaults.removeObject(forKey: Key.manualPauseEnd)
            }
        }
    }

    /// Schedules the monitor extension currently believes are inside their window.
    ///
    /// Tracked as a set because overlapping windows are legal — the shield only lifts once the last
    /// one ends.
    static var activeScheduleIDs: Set<UUID> {
        get {
            let raw = defaults.stringArray(forKey: Key.activeScheduleIDs) ?? []
            return Set(raw.compactMap(UUID.init(uuidString:)))
        }
        set {
            defaults.set(newValue.map(\.uuidString), forKey: Key.activeScheduleIDs)
        }
    }

    static func markScheduleActive(_ id: UUID) {
        activeScheduleIDs.insert(id)
    }

    static func markScheduleInactive(_ id: UUID) {
        activeScheduleIDs.remove(id)
    }

    // MARK: - Derived state

    /// The truth about whether a pause should be running right now, computed from stored facts
    /// rather than from whatever the UI last displayed.
    ///
    /// Recomputing from the clock is what lets the app recover from a missed extension callback, a
    /// reboot, or a force-quit.
    static func resolvedState(at date: Date = Date()) -> PauseState {
        var candidates: [(Date, PauseSource)] = []

        if let manualEnd = manualPauseEnd, manualEnd > date {
            candidates.append((manualEnd, .manual))
        }

        for schedule in schedules {
            if let end = schedule.currentWindowEnd(at: date) {
                candidates.append((end, .schedule(id: schedule.id)))
            }
        }

        // Whichever pause runs longest is the one that governs; a manual pause layered on top of a
        // scheduled window shouldn't end early just because the window closed.
        guard let winner = candidates.max(by: { $0.0 < $1.0 }) else { return .inactive }
        return .active(until: winner.0, source: winner.1)
    }
}
