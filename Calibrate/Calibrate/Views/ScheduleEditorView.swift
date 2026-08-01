import SwiftUI

struct ScheduleEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draft: PauseSchedule
    @State private var startDate: Date
    @State private var endDate: Date

    private let onSave: (PauseSchedule) -> Void

    init(schedule: PauseSchedule, onSave: @escaping (PauseSchedule) -> Void) {
        _draft = State(initialValue: schedule)
        _startDate = State(
            initialValue: Self.date(hour: schedule.startHour, minute: schedule.startMinute)
        )
        _endDate = State(
            initialValue: Self.date(hour: schedule.endHour, minute: schedule.endMinute)
        )
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name (optional)", text: $draft.label)
                        .font(Theme.body)
                }
                .listRowBackground(Theme.surfaceColor)

                Section("Days") {
                    weekdayPicker
                }
                .listRowBackground(Theme.surfaceColor)

                Section("Hours") {
                    DatePicker(
                        "Starts",
                        selection: $startDate,
                        displayedComponents: .hourAndMinute
                    )
                    DatePicker(
                        "Ends",
                        selection: $endDate,
                        displayedComponents: .hourAndMinute
                    )
                }
                .listRowBackground(Theme.surfaceColor)

                Section {
                    Toggle("Active", isOn: $draft.isEnabled)
                } footer: {
                    Text(footerText)
                }
                .listRowBackground(Theme.surfaceColor)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundColor)
            .navigationTitle(draft.label.isEmpty ? "Quiet hours" : draft.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!candidate.isValid)
                }
            }
        }
    }

    // MARK: - Weekdays

    private var weekdayPicker: some View {
        HStack(spacing: 6) {
            ForEach(1...7, id: \.self) { weekday in
                Button {
                    if draft.weekdays.contains(weekday) {
                        draft.weekdays.remove(weekday)
                    } else {
                        draft.weekdays.insert(weekday)
                    }
                } label: {
                    Text(String(PauseSchedule.weekdaySymbols[weekday].prefix(1)))
                        .font(Theme.rounded(15, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(
                            draft.weekdays.contains(weekday)
                                ? Theme.surfaceColor
                                : Theme.secondaryTextColor
                        )
                        .background(
                            draft.weekdays.contains(weekday)
                                ? Theme.sageDeepColor
                                : Theme.sageSoftColor
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Saving

    /// The draft with the pickers' times folded back in, so validation reflects what Save would
    /// actually store.
    private var candidate: PauseSchedule {
        var updated = draft
        let calendar = Calendar.current
        updated.startHour = calendar.component(.hour, from: startDate)
        updated.startMinute = calendar.component(.minute, from: startDate)
        updated.endHour = calendar.component(.hour, from: endDate)
        updated.endMinute = calendar.component(.minute, from: endDate)
        return updated
    }

    private func save() {
        onSave(candidate)
        dismiss()
    }

    private var footerText: String {
        let candidate = self.candidate
        if candidate.weekdays.isEmpty {
            return "Pick at least one day."
        }
        if candidate.durationMinutes < PauseDuration.minimumMinutes {
            return "Windows need to be at least \(PauseDuration.minimumMinutes) minutes long."
        }
        if candidate.crossesMidnight {
            return "This window crosses midnight, so it ends the following morning. The days above are the nights it starts on."
        }
        return "Runs \(candidate.timeSummary) on the days selected above."
    }

    private static func date(hour: Int, minute: Int, calendar: Calendar = .current) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? Date()
    }
}
