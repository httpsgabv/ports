import SwiftUI

struct RootView: View {
    @Environment(PortStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                CapsLabel("Ports", color: Theme.textPrimary)
                Spacer()
                CapsLabel("\(store.processes.count) active")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().overlay(Theme.border)

            if store.processes.isEmpty {
                CapsLabel("No open ports")
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                // Placeholder até a spec 04 (port-list-ui).
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(store.processes) { p in
                        Text("\(p.name)  " + p.ports.map { ":\($0)" }.joined(separator: " "))
                            .font(Theme.mono())
                            .foregroundStyle(store.isStale(p) ? Theme.stale : Theme.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            }

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
        .onAppear { store.isPopoverOpen = true }
        .onDisappear { store.isPopoverOpen = false }
        .task { await store.refresh() }
    }
}
