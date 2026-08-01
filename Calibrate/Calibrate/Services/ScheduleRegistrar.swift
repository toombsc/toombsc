import DeviceActivity
import Foundation

enum ScheduleError: LocalizedError {
    case tooManyActivities(needed: Int, limit: Int)
    case monitoringFailed(String)
    case durationTooShort

    var errorDescription: String? {
        switch self {
        case let .tooManyActivities(needed, limit):
            return "That's \(needed) daily windows, and iOS allows \(limit). Try covering fewer days, or combining schedules."
        case let .monitoringFailed(reason):
            return "Calibrate couldn't set that schedule. \(reason)"
        case .durationTooShort:
            return "Pauses need to be at least \(PauseDuration.minimumMinutes) minutes."
        }
    }
}

/// Registers time windows with `DeviceActivityCenter` so the monitor extension gets woken at the
/// boundaries — including when Calibrate itself isn't running.
enum ScheduleRegistrar {
    /// iOS throws `excessiveActivities` past 20 concurrently monitored activities. One slot is held
    /// back so a manual pause can always be started, no matter how full the schedule list is.
    static let activityLimit = 20
    static let scheduleBudget = activityLimit - 1

    private static var center: DeviceActivityCenter { DeviceActivityCenter() }

    // MARK: - Recurring schedules

    /// Number of activities a schedule list will consume.
    ///
    /// `DeviceActivitySchedule` has no day-of-week concept — it repeats every day — so the only way
    /// to express "weeknights" is one registration per weekday. A Mon–Fri window costs five.
    static func activityCount(for schedules: [PauseSchedule]) -> Int {
        schedules
            .filter { $0.isEnabled && $0.isValid }
            .reduce(0) { $0 + $1.weekdays.count }
    }

    static func validate(_ schedules: [PauseSchedule]) throws {
        let needed = activityCount(for: schedules)
        guard needed <= scheduleBudget else {
            throw ScheduleError.tooManyActivities(needed: needed, limit: scheduleBudget)
        }
    }

    /// Replaces every registered schedule window with the given list.
    ///
    /// Tearing all of them down first keeps the registry honest after edits and deletions; there's
    /// no cheap way to diff `DeviceActivityName`s against what iOS actually holds.
    static func registerAll(_ schedules: [PauseSchedule]) throws {
        try validate(schedules)

        let center = self.center
        let stale = center.activities.filter { name in
            if case .schedule = PauseActivity(name: name) { return true }
            return false
        }
        if !stale.isEmpty {
            center.stopMonitoring(stale)
        }

        for schedule in schedules where schedule.isEnabled && schedule.isValid {
            for weekday in schedule.weekdays {
                // The weekday is set on the start only. Pinning it on the end too would break
                // windows that cross midnight — a 10 PM Friday start ends at 7 AM Saturday, and
                // naming Friday on the end would ask iOS for a time that never arrives.
                let interval = DeviceActivitySchedule(
                    intervalStart: DateComponents(
                        hour: schedule.startHour,
                        minute: schedule.startMinute,
                        weekday: weekday
                    ),
                    intervalEnd: DateComponents(
                        hour: schedule.endHour,
                        minute: schedule.endMinute
                    ),
                    repeats: true
                )

                do {
                    try center.startMonitoring(
                        PauseActivity.schedule(id: schedule.id, weekday: weekday).name,
                        during: interval
                    )
                } catch {
                    throw ScheduleError.monitoringFailed(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Manual pause

    /// Registers a one-off window so the shield lifts on its own.
    ///
    /// This is the piece that makes a manual pause survive the app being force-quit: an in-process
    /// `Timer` dies with the app, but the monitor extension gets woken by the system at
    /// `intervalDidEnd` regardless.
    @discardableResult
    static func startManual(minutes: Int, from start: Date = Date()) throws -> Date {
        guard minutes >= PauseDuration.minimumMinutes else {
            throw ScheduleError.durationTooShort
        }

        let end = start.addingTimeInterval(TimeInterval(minutes * 60))
        let calendar = Calendar.current
        let fields: Set<Calendar.Component> = [.hour, .minute, .second]

        let interval = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents(fields, from: start),
            intervalEnd: calendar.dateComponents(fields, from: end),
            repeats: false
        )

        stopManual()
        do {
            try center.startMonitoring(PauseActivity.manual.name, during: interval)
        } catch {
            throw ScheduleError.monitoringFailed(error.localizedDescription)
        }
        return end
    }

    static func stopManual() {
        center.stopMonitoring([PauseActivity.manual.name])
    }

    static func stopAll() {
        center.stopMonitoring()
    }
}
