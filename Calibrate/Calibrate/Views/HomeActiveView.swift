import SwiftUI

/// The pause in progress.
///
/// Informational only, by design — there is no unlock control anywhere on this screen, not even a
/// disabled one. Per the brief, the commitment isn't negotiable once made, and an affordance you
/// can see is an affordance you argue with.
struct HomeActiveView: View {
    let state: PauseState

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "leaf.fill")
                .font(.system(size: 30))
                .foregroundStyle(Theme.sageColor)

            Text("Taking a pause")
                .font(Theme.title)
                .foregroundStyle(Theme.primaryTextColor)

            if let end = state.endsAt {
                // `.timer` style keeps counting on its own — no polling, and it stays correct across
                // backgrounding without a Timer to leak.
                Text(end, style: .timer)
                    .font(Theme.countdown)
                    .monospacedDigit()
                    .foregroundStyle(Theme.sageDeepColor)
                    .contentTransition(.numericText())

                Text("You'll have your apps back at \(Self.timeString(end)).")
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Text(footnote)
                .font(Theme.caption)
                .foregroundStyle(Theme.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Metrics.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footnote: String {
        if case let .active(_, source) = state, case .schedule = source {
            return "This is one of your scheduled quiet hours."
        }
        return "Calls and emergency features are never blocked."
    }

    static func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
