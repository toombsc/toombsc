import Foundation
import ManagedSettings
import ManagedSettingsUI
import UIKit

/// The screen you actually see when you tap a paused app.
///
/// iOS's default is a gray "Restricted" panel, which is exactly the scolding tone the brief rules
/// out. This replaces it with the sage palette and the same gentle language used everywhere else.
/// There is no secondary button, because a way out of the shield would defeat the whole point.
final class ShieldConfigurationProvider: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        calibrateConfiguration()
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        calibrateConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        calibrateConfiguration()
    }

    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        calibrateConfiguration()
    }

    private func calibrateConfiguration() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: Theme.background.withAlphaComponent(0.94),
            icon: UIImage(systemName: "leaf.fill")?
                .withTintColor(Theme.sage, renderingMode: .alwaysOriginal),
            title: ShieldConfiguration.Label(
                text: "Taking a pause",
                color: Theme.primaryText
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitleText(),
                color: Theme.secondaryText
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Okay",
                color: Theme.sageDeep
            ),
            primaryButtonBackgroundColor: Theme.sageSoft
        )
    }

    /// Tells you when the apps come back, so the screen answers the obvious question instead of
    /// just refusing.
    private func subtitleText() -> String {
        guard let end = SharedStore.resolvedState().endsAt else {
            return "You'll have this back in a moment."
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "You'll have this back at \(formatter.string(from: end))."
    }
}
