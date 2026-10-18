import PortsCore
import SwiftUI

/// Projeto com 2+ processos: linha resumo + filhos ao expandir. O × mata o grupo inteiro.
struct GroupRow: View {
    let group: ProcessGroup
    let isStale: (ListeningProcess) -> Bool
    let isExpanded: Bool
    let expandedProcess: String?
    let onToggle: () -> Void
    let onToggleProcess: (String) -> Void
    let onKill: (ListeningProcess) async -> KillResult
    let onKillAll: () async -> [KillResult]
    let onExpect: (ListeningProcess) -> Void
    let onExpectAll: () -> Void

    @State private var hovering = false
    @State private var killing = false
    @State private var error: String?

    private static let maxChips = 3
    private var name: String { group.project?.name ?? "—" }

    var body: some View {
        VStack(spacing: 0) {
            summary
            if isExpanded {
                ForEach(group.processes) { process in
                    Rectangle().fill(Theme.border).frame(height: Theme.hairline).padding(.leading, 30)
                    ProcessRow(
                        process: process,
                        isStale: isStale(process),
                        isExpanded: expandedProcess == process.id,
                        inGroup: true,
                        onToggleExpected: { onExpect(process) },
                        onToggle: { onToggleProcess(process.id) },
                        onKill: { await onKill(process) }
                    )
                }
                .transition(.opacity)
            }
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Circle().fill(Theme.live).frame(width: 6, height: 6)
                Text(name)
                    .font(Theme.font(13, .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .accessibilityLabel("\(name), \(group.processes.count) servers, ports \(group.ports.map(String.init).joined(separator: ", "))")
                CapsLabel("\(group.processes.count) servers")
                    .fixedSize()
                    .accessibilityHidden(true)
                Spacer(minLength: 8)
                ForEach(group.ports.prefix(Self.maxChips), id: \.self) { PortChip(port: $0) }
                if group.ports.count > Self.maxChips {
                    CapsLabel("+\(group.ports.count - Self.maxChips)")
                }
                KillButton(name: name, killing: killing) { await killAll() }
            }

            HStack(spacing: 0) {
                if let root = group.project?.root {
                    Text(abbreviateHome(root)).lineLimit(1).truncationMode(.middle)
                    Text(" · ")
                }
                Text(formatBytes(group.memoryBytes)).fixedSize()
            }
            .font(Theme.font(11))
            .foregroundStyle(Theme.textSecondary)
            .padding(.leading, 14)
            .accessibilityHidden(true)

            if isExpanded {
                ActionButton(title: "Expect all", action: onExpectAll)
                    .help("Don't count or highlight these processes")
                    .padding(.leading, 14)
                    .padding(.top, 2)
            }

            if let error {
                Text(error)
                    .font(Theme.font(11))
                    .foregroundStyle(Theme.danger)
                    .padding(.leading, 14)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(hovering || isExpanded ? Theme.surface : .clear)
        .overlay(alignment: .leading) {
            if group.processes.contains(where: isStale) { Rectangle().fill(Theme.stale).frame(width: 2) }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
        .onHover { hovering = $0 }
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: isExpanded ? "Hide servers" : "Show servers", onToggle)
    }

    private func killAll() async {
        killing = true
        error = nil
        let failures = await onKillAll().compactMap(\.failure)
        killing = false
        guard let first = failures.first else { return }
        error = "\(failures.count) of \(group.processes.count) failed: \(first)"
        try? await Task.sleep(for: .seconds(3))
        error = nil
    }
}
