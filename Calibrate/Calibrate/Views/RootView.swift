import FamilyControls
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var coordinator: PauseCoordinator
    @EnvironmentObject private var authorization: AuthorizationService

    var body: some View {
        ZStack {
            Theme.backgroundColor.ignoresSafeArea()

            if authorization.status == .approved {
                HomeView()
                    .transition(.opacity)
            } else {
                AuthorizationGateView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authorization.status)
        .task {
            await authorization.requestIfNeeded()
            if authorization.status == .approved {
                coordinator.refreshRegistrations()
            }
        }
    }
}

/// Shown until Screen Time access is granted. Explains why before asking, rather than firing a
/// system prompt at a cold start with no context.
struct AuthorizationGateView: View {
    @EnvironmentObject private var authorization: AuthorizationService

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "leaf.fill")
                .font(.system(size: 54))
                .foregroundStyle(Theme.sageColor)

            VStack(spacing: 12) {
                Text("Calibrate needs Screen Time access")
                    .font(Theme.title)
                    .foregroundStyle(Theme.primaryTextColor)
                    .multilineTextAlignment(.center)

                Text("That's what lets it hold apps aside for you. Everything stays on this phone — nothing is sent anywhere.")
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }

            if let message = authorization.errorMessage {
                Text(message)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button {
                Task { await authorization.requestIfNeeded() }
            } label: {
                Text(authorization.isRequesting ? "Waiting…" : "Continue")
            }
            .buttonStyle(SoftButtonStyle())
            .disabled(authorization.isRequesting)

            if authorization.status == .denied {
                Text("If you've already declined, you can turn this on in Settings › Screen Time.")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Theme.Metrics.screenPadding)
    }
}
