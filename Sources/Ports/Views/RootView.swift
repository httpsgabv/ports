import SwiftUI

struct RootView: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                CapsLabel("Ports", color: Theme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().overlay(Theme.border)

            CapsLabel("No open ports")
                .frame(maxWidth: .infinity, minHeight: 120)

            Divider().overlay(Theme.border)

            HStack {
                Spacer()
                Button {
                    NSApp.terminate(nil)
                } label: {
                    CapsLabel("Quit", color: Theme.textSecondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("q")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: Theme.width)
        .background(Theme.bg)
        .preferredColorScheme(.dark)
    }
}
