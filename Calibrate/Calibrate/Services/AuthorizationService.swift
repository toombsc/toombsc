import FamilyControls
import Foundation

/// Wraps the one-time Screen Time permission request.
///
/// `.individual` is the right enrollment for this app: Calibrate restricts the device it's installed
/// on, for the person holding it, rather than a child's device managed from a parent's. It's iOS 16+
/// and requires the device passcode to approve.
///
/// The status is mirrored into a `@Published` property and refreshed explicitly rather than observed
/// on `AuthorizationCenter`, so the UI's refresh points stay obvious and don't depend on the
/// framework's observation behavior.
@MainActor
final class AuthorizationService: ObservableObject {
    @Published private(set) var status: AuthorizationStatus
    @Published private(set) var isRequesting = false
    @Published var errorMessage: String?

    init() {
        status = AuthorizationCenter.shared.authorizationStatus
    }

    func refresh() {
        status = AuthorizationCenter.shared.authorizationStatus
    }

    func requestIfNeeded() async {
        refresh()
        guard status != .approved, !isRequesting else { return }

        isRequesting = true
        defer {
            isRequesting = false
            refresh()
        }

        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            errorMessage = nil
        } catch {
            // Usually a declined prompt, a device whose Screen Time is managed by someone else, or a
            // build missing the Family Controls entitlement.
            errorMessage = "Calibrate couldn't get Screen Time access. \(error.localizedDescription)"
        }
    }
}
