import SwiftUI
import UIKit

/// The visual vocabulary described in the brief: muted sage, warm grays, gentle off-whites, rounded
/// everything.
///
/// Colors are declared in code rather than in an asset catalog so the shield extension can share
/// this one file without also needing target membership in the app's asset catalog. Each is a
/// dynamic `UIColor`, since the shield screen renders against whatever appearance the system is in
/// and a fixed light palette would be unreadable at night — which is exactly when this app gets
/// used.
enum Theme {

    // MARK: - Palette

    static let background = dynamic(light: 0xFAF8F4, dark: 0x1B1A18)
    static let surface = dynamic(light: 0xFFFFFF, dark: 0x272521)
    static let primaryText = dynamic(light: 0x3D3A34, dark: 0xEFEBE3)
    static let secondaryText = dynamic(light: 0x8A857B, dark: 0xA8A296)
    static let sage = dynamic(light: 0x7E9A7C, dark: 0x90AE8E)
    static let sageDeep = dynamic(light: 0x5F7A5E, dark: 0xB2CBB0)
    static let sageSoft = dynamic(light: 0xDCE5DA, dark: 0x333E32)
    static let divider = dynamic(light: 0xEAE6DE, dark: 0x38352F)

    // SwiftUI mirrors of the same colors.
    static var backgroundColor: Color { Color(uiColor: background) }
    static var surfaceColor: Color { Color(uiColor: surface) }
    static var primaryTextColor: Color { Color(uiColor: primaryText) }
    static var secondaryTextColor: Color { Color(uiColor: secondaryText) }
    static var sageColor: Color { Color(uiColor: sage) }
    static var sageDeepColor: Color { Color(uiColor: sageDeep) }
    static var sageSoftColor: Color { Color(uiColor: sageSoft) }
    static var dividerColor: Color { Color(uiColor: divider) }

    // MARK: - Metrics

    enum Metrics {
        static let cardRadius: CGFloat = 24
        static let controlRadius: CGFloat = 18
        static let pauseButtonSize: CGFloat = 232
        static let screenPadding: CGFloat = 24
        static let stackSpacing: CGFloat = 20
    }

    // MARK: - Type

    /// Rounded throughout — the brief asks for no sharp edges, and that includes the letterforms.
    static func rounded(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static var title: Font { rounded(30, weight: .semibold) }
    static var countdown: Font { rounded(66, weight: .light) }
    static var body: Font { rounded(17) }
    static var caption: Font { rounded(14) }
    static var buttonLabel: Font { rounded(21, weight: .medium) }

    // MARK: - Helpers

    private static func dynamic(light: Int, dark: Int) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        }
    }
}

extension UIColor {
    fileprivate convenience init(hex: Int) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

/// A single soft tap on activation, per the brief — never the harsh buzz.
enum Haptics {
    static func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Shared view styling

/// The rounded, generously padded card used for every grouped block in the app.
struct CalibrateCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(Theme.Metrics.screenPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surfaceColor)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius, style: .continuous))
    }
}

/// Full-width secondary action. Deliberately quiet so it never competes with Take a Pause.
struct SoftButtonStyle: ButtonStyle {
    var tint: Color = Theme.sageDeepColor
    var fill: Color = Theme.sageSoftColor

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.buttonLabel)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.controlRadius, style: .continuous))
            .opacity(configuration.isPressed ? 0.75 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
