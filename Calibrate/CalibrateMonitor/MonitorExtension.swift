import DeviceActivity
import Foundation

/// Woken by the system at the edges of every registered window — including when Calibrate itself
/// isn't running. This is what actually lifts a pause.
///
/// Deliberately minimal. `DeviceActivityMonitor` extensions run under tight memory and wall-clock
/// limits, and getting killed here means a shield that never lifts, so this does nothing but read
/// the shared container and touch the settings store.
final class MonitorExtension: DeviceActivityMonitor {

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        guard let parsed = PauseActivity(name: activity) else { return }

        if case let .schedule(id, _) = parsed {
            SharedStore.markScheduleActive(id)
        }

        // For a manual pause the app already applied the shield on tap; re-applying is harmless and
        // covers the case where the app was killed before it could.
        ShieldController.apply(SharedStore.selection)
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard let parsed = PauseActivity(name: activity) else { return }

        switch parsed {
        case .manual:
            SharedStore.manualPauseEnd = nil
        case let .schedule(id, _):
            SharedStore.markScheduleInactive(id)
        }

        // One window ending doesn't mean the pause is over — a manual pause can outlast a scheduled
        // window, and overlapping schedules are legal. Only lift when nothing is holding it open.
        if SharedStore.resolvedState().isActive {
            ShieldController.apply(SharedStore.selection)
        } else {
            ShieldController.clear()
        }
    }
}
