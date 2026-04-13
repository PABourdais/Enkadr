import SwiftUI

enum Theme {
    // Core palette — derived from the app icon
    static let accent = Color(red: 0.91, green: 0.52, blue: 0.49)      // #E8847C
    static let accentDark = Color(red: 0.78, green: 0.38, blue: 0.35)  // #C76059

    // Backgrounds
    static let bg = Color(red: 0.11, green: 0.11, blue: 0.12)          // #1C1C1E
    static let bgSecondary = Color(red: 0.15, green: 0.15, blue: 0.16) // #262628
    static let bgTertiary = Color(red: 0.19, green: 0.19, blue: 0.20)  // #303033

    // Text
    static let textPrimary = Color(white: 0.93)
    static let textSecondary = Color(white: 0.60)
    static let textTertiary = Color(white: 0.40)

    // Borders & dividers
    static let border = Color(white: 0.25)
    static let divider = Color(white: 0.20)
}

struct AccentButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(!isEnabled ? Theme.textTertiary : (configuration.isPressed ? Theme.accentDark : Theme.accent))
            )
    }
}
