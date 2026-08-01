import Combine
import FamilyControls
import Foundation

/// Single source of truth for the app's UI, and the place where drift gets corrected.
///
/// The extensions can change the world while the app is asleep, so nothing here trusts its own
/// in-memory state across a lifecycle boundary — `reconcile()` recomputes from stored facts and the
/// clock, then makes the shield match.
@MainActor
final class PauseCoordinator: ObservableObject {
    @Published private(set) var state: PauseState = .inactive
    @Published private(set) var selection: FamilyActivitySelection
    @Published private(set) var schedules: [PauseSchedule]
    @Published var errorMessage: String?

    private var expiryTimer: Timer?

    init() {
        selection = SharedStore.selection
        schedules = SharedStore.schedules
        reconcile()
    }

    deinit {
        expiryTimer?.invalidate()
    }

    // MARK: - Derived

    /// The brief calls for app and schedule changes to be locked down mid-pause, so there's no
    /// editing your way out of a commitment you already made.
    var canEditSettings: Bool { !state.isActive }

    var hasSelection: Bool { SharedStore.hasSelection }

    var selectedAppCount: Int {
        selection.applicationTokens.count
            + selection.categoryTokens.count
            + selection.webDomainTokens.count
    }

    /// The soonest upcoming window, for the home screen's "Tonight: pausing 10 PM to 7 AM" line.
    var nextScheduled: (schedule: PauseSchedule, start: Date)? {
        let now = Date()
        return schedules
            .compactMap { schedule -> (PauseSchedule, Date)? in
                guard let start = schedule.nextStart(after: now) else { return nil }
                return (schedule, start)
            }
            .min { $0.1 < $1.1 }
            .map { (schedule: $0.0, start: $0.1) }
    }

    // MARK: - Reconciliation

    /// Recomputes what *should* be true and forces reality to match.
    ///
    /// Called on launch and every foreground. This is what recovers the app if the monitor extension
    /// was never woken, the device rebooted mid-pause, or a schedule was edited elsewhere.
    func reconcile() {
        selection = SharedStore.selection
        schedules = SharedStore.schedules

        let resolved = SharedStore.resolvedState()

        switch resolved {
        case .active:
            ShieldController.apply(SharedStore.selection)
        case .inactive:
            ShieldController.clear()
            if SharedStore.manualPauseEnd != nil {
                SharedStore.manualPauseEnd = nil
                ScheduleRegistrar.stopManual()
            }
            if !SharedStore.activeScheduleIDs.isEmpty {
                SharedStore.activeScheduleIDs = []
            }
        }

        state = resolved
        scheduleExpiryCheck()
    }

    /// Wakes the UI once at expiry so the countdown screen releases itself without polling.
    private func scheduleExpiryCheck() {
        expiryTimer?.invalidate()
        expiryTimer = nil

        guard let end = state.endsAt else { return }
        let interval = max(1, end.timeIntervalSinceNow + 1)
        expiryTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.reconcile() }
        }
    }

    // MARK: - Manual pause

    func startManualPause(minutes: Int) {
        guard hasSelection else {
            errorMessage = "Pick the apps you'd like to step away from first, in Settings."
            return
        }

        do {
            let end = try ScheduleRegistrar.startManual(minutes: minutes)
            SharedStore.manualPauseEnd = end
            // Applied here rather than waiting on the extension's interval start, so the shield is
            // in place the instant the button is tapped.
            ShieldController.apply(SharedStore.selection)
            Haptics.soft()
            reconcile()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Settings

    func update(selection newValue: FamilyActivitySelection) {
        guard canEditSettings else { return }
        SharedStore.selection = newValue
        selection = newValue
    }

    func save(_ schedule: PauseSchedule) {
        var updated = schedules
        if let index = updated.firstIndex(where: { $0.id == schedule.id }) {
            updated[index] = schedule
        } else {
            updated.append(schedule)
        }
        persist(updated)
    }

    func delete(scheduleWithID id: UUID) {
        persist(schedules.filter { $0.id != id })
    }

    func setEnabled(_ isEnabled: Bool, forScheduleWithID id: UUID) {
        var updated = schedules
        guard let index = updated.firstIndex(where: { $0.id == id }) else { return }
        updated[index].isEnabled = isEnabled
        persist(updated)
    }

    /// Persists only if the whole list can actually be registered, so a rejected edit leaves the
    /// saved schedules and the live registrations agreeing with each other.
    private func persist(_ updated: [PauseSchedule]) {
        guard canEditSettings else { return }
        do {
            try ScheduleRegistrar.validate(updated)
            SharedStore.schedules = updated
            schedules = updated
            try ScheduleRegistrar.registerAll(updated)
            reconcile()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Re-registers everything after a fresh install or a permission grant, when iOS holds no
    /// activities for us yet.
    func refreshRegistrations() {
        do {
            try ScheduleRegistrar.registerAll(SharedStore.schedules)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
