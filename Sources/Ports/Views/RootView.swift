import PortsCore
import SwiftUI

struct RootView: View {
    @Environment(PortStore.self) private var store
    @State private var expanded: Int32?
    @State private var listHeight: CGFloat = 0
    @State private var showingPreferences = false

    var body: some View {
        Group {
            if showingPreferences {
                PreferencesView { showingPreferences = false }
            } else {
                main
            }
        }
        .frame(width: Theme.width)
        .background(Theme.bg)
        .preferredColorScheme(.dark)
        .onAppear { store.isPopoverOpen = true }
        .onDisappear { store.isPopoverOpen = false }
        .task { await store.refresh() }
    }

    private var main: some View {
        VStack(spacing: 0) {
            header
            hairline
            if store.processes.isEmpty {
                CapsLabel("No open ports")
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                list
            }
            hairline
            footer
        }
    }

    private var header: some View {
        HStack {
            CapsLabel("Ports", color: Theme.textPrimary)
            Spacer()
            CapsLabel("\(store.processes.count) active")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(store.processes) { process in
                    ProcessRow(
                        process: process,
                        isStale: store.isStale(process),
                        isExpanded: expanded == process.pid,
                        onToggle: { toggle(process.pid) },
                        onKill: { await kill(process) }
                    )
                    .transition(.opacity)
                    if process.id != store.processes.last?.id { hairline }
                }
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { listHeight = $0 }
        }
        .scrollIndicators(.never)
        .frame(height: min(listHeight, 440))   // popover cresce com o conteúdo até ~520pt no total
    }

    private var footer: some View {
        HStack {
            if store.lastError != nil {
                CapsLabel("Scan failed · retrying", color: Theme.danger)
            } else if let lastScan = store.lastScan {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    CapsLabel("Updated \(formatUptime(context.date.timeIntervalSince(lastScan)))")
                }
            }
            Spacer()
            Button { showingPreferences = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(Theme.textSecondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(",")
            .help("Preferences")
            .accessibilityLabel("Preferences")
            .padding(.trailing, 12)
            Button { NSApp.terminate(nil) } label: {
                CapsLabel("Quit", color: Theme.textSecondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var hairline: some View {
        Rectangle().fill(Theme.border).frame(height: Theme.hairline)
    }

    private func toggle(_ pid: Int32) {
        withAnimation(.easeOut(duration: 0.15)) {
            expanded = expanded == pid ? nil : pid
        }
    }

    private func kill(_ process: ListeningProcess) async -> KillResult {
        let result = await terminate(process)
        if case .failed = result { return result }
        withAnimation(.easeOut(duration: 0.2)) { store.remove(process.pid) }
        await store.refresh()
        return result
    }
}
