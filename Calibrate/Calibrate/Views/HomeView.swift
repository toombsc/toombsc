import SwiftUI

/// Routes between the two home states described in the brief. Settings stays reachable in both, but
/// becomes read-only mid-pause rather than disappearing.
struct HomeView: View {
    @EnvironmentObject private var coordinator: PauseCoordinator

    @State private var showingSettings = false
    @State private var showingDurationPicker = false

    var body: some View {
        VStack(spacing: 0) {
            header

            if coordinator.state.isActive {
                HomeActiveView(state: coordinator.state)
            } else {
                HomeInactiveView { showingDurationPicker = true }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: coordinator.state.isActive)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(coordinator)
        }
        .sheet(isPresented: $showingDurationPicker) {
            DurationPickerView { minutes in
                showingDurationPicker = false
                coordinator.startManualPause(minutes: minutes)
            }
        }
        .alert("Something's off", isPresented: errorBinding) {
            Button("Okay", role: .cancel) {}
        } message: {
            Text(coordinator.errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(Theme.secondaryTextColor)
                    .padding(10)
            }
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, Theme.Metrics.screenPadding - 10)
        .padding(.top, 8)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { coordinator.errorMessage != nil },
            set: { if !$0 { coordinator.errorMessage = nil } }
        )
    }
}
