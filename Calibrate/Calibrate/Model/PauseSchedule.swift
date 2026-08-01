import Foundation

/// A recurring window during which the selected apps are paused.
///
/// Weekdays use `Calendar` numbering (1 = Sunday … 7 = Saturday) so they drop straight into
/// `DateComponents.weekday` with no translation.
///
/// A window may cross midnight — "10 PM to 7 AM" is the motivating case from the brief. When it
/// does, the weekday refers to the day the window *starts*, so a Mon–Fri schedule ending at 7 AM
/// releases on Saturday morning.
struct PauseSchedule: Codable, Identifiable, Hashable {
    var id: UUID
    var label: String
    var weekdays: Set<Int>
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        label: String = "",
        weekdays: Set<Int> = [2, 3, 4, 5, 6],
        startHour: Int = 22,
        startMinute: Int = 0,
        endHour: Int = 7,
        endMinute: Int = 0,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.label = label
        self.weekdays = weekdays
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.isEnabled = isEnabled
    }

    // MARK: - Timing

    var startMinutes: Int { startHour * 60 + startMinute }
    var endMinutes: Int { endHour * 60 + endMinute }

    var crossesMidnight: Bool { endMinutes <= startMinutes }

    /// Length of the window. A window whose start and end match is treated as a full day rather
    /// than a zero-length no-op, which is the less surprising reading of "10 PM to 10 PM".
    var durationMinutes: Int {
        let delta = (endMinutes - startMinutes + 24 * 60) % (24 * 60)
        return delta == 0 ? 24 * 60 : delta
    }

    /// `DeviceActivitySchedule` enforces a 15-minute floor; anything shorter silently fails to
    /// register, so the editor blocks it up front.
    var isValid: Bool {
        !weekdays.isEmpty && durationMinutes >= PauseDuration.minimumMinutes
    }

    // MARK: - Occurrence math

    /// If `date` falls inside one of this schedule's windows, the moment that window ends.
    ///
    /// Checks each selected weekday's most recent start, which handles cross-midnight windows
    /// naturally: at 2 AM Saturday we're still inside Friday's 10 PM start.
    func currentWindowEnd(at date: Date, calendar: Calendar = .current) -> Date? {
        guard isEnabled else { return nil }
        for weekday in weekdays {
            guard let start = mostRecentStart(onOrBefore: date, weekday: weekday, calendar: calendar)
            else { continue }
            let end = start.addingTimeInterval(TimeInterval(durationMinutes * 60))
            if start <= date && date < end { return end }
        }
        return nil
    }

    /// The next time this schedule begins, for the home screen summary.
    func nextStart(after date: Date, calendar: Calendar = .current) -> Date? {
        guard isEnabled else { return nil }
        return weekdays.compactMap { weekday -> Date? in
            var components = DateComponents()
            components.weekday = weekday
            components.hour = startHour
            components.minute = startMinute
            return calendar.nextDate(
                after: date,
                matching: components,
                matchingPolicy: .nextTime,
                direction: .forward
            )
        }
        .min()
    }

    private func mostRecentStart(
        onOrBefore date: Date,
        weekday: Int,
        calendar: Calendar
    ) -> Date? {
        var components = DateComponents()
        components.weekday = weekday
        components.hour = startHour
        components.minute = startMinute
        // Search backward from one second ahead so a window starting exactly now counts as started.
        return calendar.nextDate(
            after: date.addingTimeInterval(1),
            matching: components,
            matchingPolicy: .nextTime,
            direction: .backward
        )
    }
}

// MARK: - Display

extension PauseSchedule {
    static let weekdaySymbols = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var weekdaySummary: String {
        let sorted = weekdays.sorted()
        switch Set(sorted) {
        case Set(1...7): return "Every day"
        case Set([2, 3, 4, 5, 6]): return "Weeknights"
        case Set([1, 7]): return "Weekends"
        default: return sorted.map { Self.weekdaySymbols[$0] }.joined(separator: ", ")
        }
    }

    var timeSummary: String {
        "\(Self.format(hour: startHour, minute: startMinute)) to \(Self.format(hour: endHour, minute: endMinute))"
    }

    var displayLabel: String {
        label.isEmpty ? weekdaySummary : label
    }

    static func format(hour: Int, minute: Int, calendar: Calendar = .current) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = calendar.date(from: components) ?? Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Manual durations

enum PauseDuration {
    /// `DeviceActivitySchedule` will not accept an interval shorter than 15 minutes.
    static let minimumMinutes = 15
    static let maximumMinutes = 12 * 60

    static let presets = [15, 30, 60, 120]

    static func label(minutes: Int) -> String {
        switch minutes {
        case ..<60: return "\(minutes) min"
        case 60: return "1 hr"
        default:
            let hours = minutes / 60
            let remainder = minutes % 60
            return remainder == 0 ? "\(hours) hr" : "\(hours) hr \(remainder) min"
        }
    }
}
