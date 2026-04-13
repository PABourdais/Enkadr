import SwiftUI

struct SettingsView: View {
    var body: some View {
        SettingsPanel()
            .padding(24)
            .frame(width: 480)
            .background(Theme.bg)
            .foregroundStyle(Theme.textPrimary)
            .preferredColorScheme(.dark)
    }
}
