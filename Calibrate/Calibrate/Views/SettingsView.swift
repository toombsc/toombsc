import FamilyControls
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var coordinator: PauseCoordinator
    @Environment(\.dismiss) private var dismiss

    @State private var showingPicker = false
    @State private var draftSelection = FamilyActivitySelection()
    @State private var editingSchedule: PauseSchedule?

    var body: some View {
        NavigationStack {
            List {
                if !coordinator.canEditSettings {
                    lockedNotice
                }

                appsSection
                schedulesSection

                if !SharedStore.isAppGroupAvailable {
                    appGroupWarning
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundColor)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .familyActivityPicker(isPresented: $showingPicker, selection: $draftSelection)
            .onChange(of: showingPicker) { isPresented in
                // The picker has no explicit commit callback; dismissal is the commit.
                guard !isPresented else { return }
                coordinator.update(selection: draftSelection)
            }
            .onAppear { draftSelection = coordinator.selection }
            .sheet(item: $editingSchedule) { schedule in
                ScheduleEditorView(schedule: schedule) { updated in
                    coordinator.save(updated)
                    editingSchedule = nil
                }
            }
        }
    }

    // MARK: - Sections

    private var lockedNotice: some View {
        Section {
            Label(
                "A pause is running. You can make changes once it ends.",
                systemImage: "leaf.fill"
            )
            .font(Theme.caption)
            .foregroundStyle(Theme.sageDeepColor)
        }
        .listRowBackground(Theme.sageSoftColor)
    }

    private var appsSection: some View {
        Section {
            Button {
                draftSelection = coordinator.selection
                showingPicker = true
            } label: {
                HStack {
                    Text("Apps to set aside")
                        .foregroundStyle(Theme.primaryTextColor)
                    Spacer()
                    Text(coordinator.selectedAppCount == 0
                         ? "None yet"
                         : "\(coordinator.selectedAppCount) selected")
                        .foregroundStyle(Theme.secondaryTextColor)
                }
            }
            .disabled(!coordinator.canEditSettings)
        } footer: {
            Text("Calls and emergency features are never blocked. Notifications still arrive — only opening the apps is paused.")
        }
        .listRowBackground(Theme.surfaceColor)
    }

    private var schedulesSection: some View {
        Section {
            ForEach(coordinator.schedules) { schedule in
                scheduleRow(schedule)
            }
            .onDelete { offsets in
                guard coordinator.canEditSettings else { return }
                for index in offsets {
                    coordinator.delete(scheduleWithID: coordinator.schedules[index].id)
                }
            }

            Button {
                editingSchedule = PauseSchedule()
            } label: {
                Label("Add a schedule", systemImage: "plus")
                    .foregroundStyle(Theme.sageDeepColor)
            }
            .disabled(!coordinator.canEditSettings)
        } header: {
            Text("Quiet hours")
        } footer: {
            Text(scheduleFooter)
        }
        .listRowBackground(Theme.surfaceColor)
    }

    private func scheduleRow(_ schedule: PauseSchedule) -> some View {
        HStack {
            Button {
                editingSchedule = schedule
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text(schedule.displayLabel)
                        .font(Theme.body)
                        .foregroundStyle(Theme.primaryTextColor)
                    Text("\(schedule.weekdaySummary) · \(schedule.timeSummary)")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryTextColor)
                }
            }
            .buttonStyle(.plain)
            .disabled(!coordinator.canEditSettings)

            Spacer()

            Toggle("", isOn: Binding(
                get: { schedule.isEnabled },
                set: { coordinator.setEnabled($0, forScheduleWithID: schedule.id) }
            ))
            .labelsHidden()
            .disabled(!coordinator.canEditSettings)
        }
    }

    private var appGroupWarning: some View {
        Section {
            Text("Calibrate can't reach its shared container. Check that the App Group \(SharedStore.appGroupID) is enabled on all three targets — without it, scheduled pauses won't lift on their own.")
                .font(Theme.caption)
                .foregroundStyle(Theme.secondaryTextColor)
        }
        .listRowBackground(Theme.surfaceColor)
    }

    /// Surfaces the per-weekday cost of schedules, since the 20-activity ceiling is invisible
    /// otherwise and only shows up as a failure to save.
    private var scheduleFooter: String {
        let used = ScheduleRegistrar.activityCount(for: coordinator.schedules)
        guard used > 0 else {
            return "Windows can cross midnight — 10 PM to 7 AM works as expected."
        }
        return "Using \(used) of \(ScheduleRegistrar.scheduleBudget) daily windows. Each day a schedule covers counts as one."
    }
}
