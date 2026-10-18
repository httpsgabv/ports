import OSLog
import PortsCore
import SwiftUI

private let log = Logger(subsystem: "dev.gabriel.ports", category: "kill")

struct RootView: View {
    @Environment(PortStore.self) private var store
    @State private var expanded: Int32?
    @State private var expandedGroup: String?
    @State private var showExpected = false
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
            if store.processes.isEmpty && store.expectedProcesses.isEmpty {
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
                let groups = groupByProject(store.processes)
                if groups.isEmpty {
                    CapsLabel("No open ports").frame(maxWidth: .infinity, minHeight: 60)
                }
                ForEach(groups) { group in
                    row(for: group).transition(.opacity)
                    if group.id != groups.last?.id { hairline }
                }
                if !store.expectedProcesses.isEmpty {
                    hairline
                    expectedSection
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
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())   // .plain só clica em pixels opacos
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

    /// Processos esperados: fora do contador e do âmbar, mas visíveis e matáveis.
    private var expectedSection: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.15)) { showExpected.toggle() }
            } label: {
                HStack {
                    CapsLabel("Expected · \(store.expectedProcesses.count)")
                    Spacer()
                    Image(systemName: showExpected ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .light))
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .contentShape(Rectangle())   // .plain só clica em pixels opacos
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(store.expectedProcesses.count) expected processes")

            if showExpected {
                ForEach(store.expectedProcesses) { process in
                    hairline
                    ProcessRow(
                        process: process,
                        isStale: false,
                        isExpanded: expanded == process.pid,
                        isExpected: true,
                        onToggleExpected: { store.setExpected([process], false) },
                        onToggle: { toggle(process.pid) },
                        onKill: { await kill(process) }
                    )
                    .opacity(0.55)
                }
                .transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private func row(for group: ProcessGroup) -> some View {
        if group.processes.count == 1, let process = group.processes.first {
            ProcessRow(
                process: process,
                isStale: store.isStale(process),
                isExpanded: expanded == process.pid,
                onToggleExpected: { store.setExpected([process], true) },
                onToggle: { toggle(process.pid) },
                onKill: { await kill(process) }
            )
        } else {
            GroupRow(
                group: group,
                isStale: store.isStale,
                isExpanded: expandedGroup == group.id,
                expandedProcess: expanded,
                onToggle: {
                    withAnimation(.easeOut(duration: 0.15)) {
                        expandedGroup = expandedGroup == group.id ? nil : group.id
                    }
                },
                onToggleProcess: toggle,
                onKill: kill,
                onKillAll: { await killAll(group) },
                onExpect: { store.setExpected([$0], true) },
                onExpectAll: { store.setExpected(group.processes, true) }
            )
        }
    }

    private func toggle(_ pid: Int32) {
        withAnimation(.easeOut(duration: 0.15)) {
            expanded = expanded == pid ? nil : pid
        }
    }

    private func kill(_ process: ListeningProcess) async -> KillResult {
        log.notice("kill pid=\(process.pid) \(process.title, privacy: .public)")
        let result = await terminate(process)
        log.notice("kill pid=\(process.pid) -> \(String(describing: result), privacy: .public)")
        if case .failed = result { return result }
        withAnimation(.easeOut(duration: 0.2)) { store.remove(process.pid) }
        await store.refresh()
        return result
    }

    private func killAll(_ group: ProcessGroup) async -> [KillResult] {
        log.notice("killAll \(group.id, privacy: .public) pids=\(group.processes.map(\.pid), privacy: .public)")
        let results = await terminateAll(group.processes)
        log.notice("killAll \(group.id, privacy: .public) -> \(String(describing: results), privacy: .public)")
        withAnimation(.easeOut(duration: 0.2)) {
            for (process, result) in zip(group.processes, results) where result.failure == nil {
                store.remove(process.pid)
            }
        }
        await store.refresh()
        return results
    }
}
