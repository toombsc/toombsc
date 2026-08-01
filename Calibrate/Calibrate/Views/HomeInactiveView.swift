import SwiftUI

/// The resting state: one large, unmistakable action and a quiet note about what's coming up.
struct HomeInactiveView: View {
    @EnvironmentObject private var coordinator: PauseCoordinator

    private let onTakePause: () -> Void

    /// Written out rather than relying on the synthesized memberwise initializer, which gets subtle
    /// once property wrappers and `private` are in the mix.
    init(onTakePause: @escaping () -> Void) {
        self.onTakePause = onTakePause
    }

    var body: some View {
        VStack(spacing: 36) {
            Spacer()

            Button(action: onTakePause) {
                VStack(spacing: 10) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 34))
                    Text("Take a Pause")
                        .font(Theme.rounded(26, weight: .medium))
                }
                .foregroundStyle(Theme.surfaceColor)
                .frame(width: Theme.Metrics.pauseButtonSize, height: Theme.Metrics.pauseButtonSize)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: [Theme.sageColor, Theme.sageDeepColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Take a pause")

            scheduleSummary

            Spacer()
        }
        .padding(Theme.Metrics.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var scheduleSummary: some View {
        if let next = coordinator.nextScheduled {
            VStack(spacing: 6) {
                Text("\(Self.dayPhrase(for: next.start)): pausing \(next.schedule.timeSummary)")
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
        } else if !coordinator.hasSelection {
            Text("Choose which apps to set aside in Settings.")
                .font(Theme.body)
                .foregroundStyle(Theme.secondaryTextColor)
                .multilineTextAlignment(.center)
        } else {
            Text("No scheduled pauses yet.")
                .font(Theme.body)
                .foregroundStyle(Theme.secondaryTextColor)
        }
    }

    /// "Tonight" reads better than "Today" for a 10 PM start, which is the common case here.
    static func dayPhrase(for date: Date, calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: date)
        let isEvening = hour >= 17

        if calendar.isDateInToday(date) {
            return isEvening ? "Tonight" : "Later today"
        }
        if calendar.isDateInTomorrow(date) {
            return isEvening ? "Tomorrow night" : "Tomorrow"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}
