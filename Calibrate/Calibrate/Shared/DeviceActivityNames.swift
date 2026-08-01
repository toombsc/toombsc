import DeviceActivity
import Foundation
import ManagedSettings

/// The single shield store mutated by both the app and the monitor extension.
///
/// Using a *named* store (rather than `ManagedSettingsStore()`) matters: the app applies the shield
/// immediately for instant feedback, and the extension lifts it later from a different process. They
/// have to be talking about the same store or they'll fight.
extension ManagedSettingsStore.Name {
    static let calibrate = Self("calibrate")
}

/// Identifies one registered `DeviceActivity` interval.
///
/// `DeviceActivityName` is just a string, so we encode enough structure into it for the monitor
/// extension to reverse it back into "which schedule, which day" without needing its own index.
enum PauseActivity: Hashable {
    /// A one-off manual pause started from the Take a Pause button.
    case manual
    /// One weekday's worth of a recurring schedule. See `ScheduleRegistrar` for why schedules fan
    /// out into one activity per weekday.
    case schedule(id: UUID, weekday: Int)

    private static let manualToken = "calibrate.manual"
    private static let schedulePrefix = "calibrate.schedule."

    var name: DeviceActivityName {
        switch self {
        case .manual:
            return DeviceActivityName(Self.manualToken)
        case let .schedule(id, weekday):
            return DeviceActivityName("\(Self.schedulePrefix)\(id.uuidString).\(weekday)")
        }
    }

    init?(name: DeviceActivityName) {
        let raw = name.rawValue
        if raw == Self.manualToken {
            self = .manual
            return
        }
        guard raw.hasPrefix(Self.schedulePrefix) else { return nil }
        let body = raw.dropFirst(Self.schedulePrefix.count)
        // UUID strings contain hyphens but no dots, so the last dot separates id from weekday.
        guard let dot = body.lastIndex(of: "."),
              let id = UUID(uuidString: String(body[body.startIndex..<dot])),
              let weekday = Int(body[body.index(after: dot)...])
        else { return nil }
        self = .schedule(id: id, weekday: weekday)
    }
}
