import SwiftUI

@main
struct CalibrateApp: App {
    @StateObject private var coordinator = PauseCoordinator()
    @StateObject private var authorization = AuthorizationService()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(coordinator)
                .environmentObject(authorization)
                .tint(Theme.sageDeepColor)
                .onChange(of: scenePhase) { phase in
                    // Extensions can start or end a pause while the app is asleep, so every return
                    // to the foreground re-derives the truth instead of trusting stale UI state.
                    guard phase == .active else { return }
                    authorization.refresh()
                    coordinator.reconcile()
                }
        }
    }
}
