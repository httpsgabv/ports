import OSLog
import PortsCore
import SwiftUI

struct ProcessRow: View {
    let process: ListeningProcess
    let isStale: Bool
    let isExpanded: Bool
    var inGroup = false   // filho de um GroupRow: indentado e sem repetir o projeto
    let onToggle: () -> Void
    let onKill: () async -> KillResult

    @State private var hovering = false
    @State private var killing = false
    @State private var error: String?

    private var uptime: String { formatUptime(Date.now.timeIntervalSince(process.startedAt)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Circle().fill(Theme.live).frame(width: 6, height: 6)
                Text(process.title)
                    .font(Theme.font(13, .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .accessibilityLabel("\(process.title), ports \(process.ports.map(String.init).joined(separator: ", ")), up \(uptime)")
                Spacer(minLength: 8)
                ForEach(process.ports, id: \.self) { PortChip(port: $0) }
                killButton
            }

            meta.padding(.leading, 14)

            if isExpanded { details.padding(.leading, 14).transition(.opacity) }

            if let error {
                Text(error)
                    .font(Theme.font(11))
                    .foregroundStyle(Theme.danger)
                    .padding(.leading, 14)
            }
        }
        .padding(.leading, inGroup ? 30 : 16)
        .padding(.trailing, 16)
        .padding(.vertical, 10)
        .background(hovering || isExpanded ? Theme.surface : .clear)
        .overlay(alignment: .leading) {
            if isStale { Rectangle().fill(Theme.stale).frame(width: 2) }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
        .onHover { hovering = $0 }
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: isExpanded ? "Hide details" : "Show details", onToggle)
    }

    private var meta: some View {
        HStack(spacing: 0) {
            if !inGroup, let place = process.project?.name ?? process.cwd.map({ abbreviateHome($0) }) {
                Text(place)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(" · ")
            }
            Text(uptime).foregroundStyle(isStale ? Theme.stale : Theme.textSecondary)
            Text(" · \(formatCPU(process.cpuPercent)) · \(formatBytes(process.memoryBytes))")
                .fixedSize()
        }
        .font(Theme.font(11))
        .foregroundStyle(Theme.textSecondary)
        .accessibilityHidden(true)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PID \(String(process.pid))" + (process.cwd.map { " · " + abbreviateHome($0) } ?? ""))
                .font(Theme.font(11))
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(1)
                .truncationMode(.middle)
            Text(process.command)
                .font(Theme.font(11))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(2)
                .truncationMode(.middle)
                .textSelection(.enabled)
            HStack(spacing: 6) {
                if let port = process.ports.first {
                    ActionButton(title: "Open ↗") { openPort(port) }
                }
                if let cwd = process.cwd {
                    ActionButton(title: "Finder") { revealInFinder(cwd) }
                }
            }
            .padding(.top, 2)
        }
    }

    private var killButton: some View {
        KillButton(name: process.title, killing: killing) {
            killing = true
            error = nil
            let result = await onKill()
            killing = false
            switch result {
            case .terminated, .killed, .alreadyGone, .pidReused: break   // a lista se atualiza
            case .failed(let message):
                error = message
                try? await Task.sleep(for: .seconds(3))
                error = nil
            }
        }
    }
}

struct PortChip: View {
    let port: UInt16
    @State private var hovering = false

    var body: some View {
        Button { openPort(port) } label: {
            Text(":\(String(port))")
                .font(Theme.font(11))
                .foregroundStyle(hovering ? Theme.textPrimary : Theme.textSecondary)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(hovering ? Theme.textTertiary : Theme.border, lineWidth: 1))
                .contentShape(Rectangle())   // .plain só clica em pixels opacos
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help("Open localhost:\(String(port))")
        .accessibilityLabel("Open port \(String(port))")
    }
}

struct KillButton: View {
    let name: String
    let killing: Bool
    let action: () async -> Void
    @State private var hovering = false

    var body: some View {
        Button {
            Logger(subsystem: "dev.gabriel.ports", category: "kill").notice("kill button tapped: \(name, privacy: .public)")
            Task { await action() }
        } label: {
            ZStack {
                if killing {
                    ProgressView().controlSize(.mini)
                } else {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(hovering ? Theme.danger : Theme.textTertiary)
                }
            }
            .frame(width: 20, height: 20)
            .background(hovering && !killing ? Theme.danger.opacity(0.12) : .clear, in: .rect(cornerRadius: 4))
            .contentShape(Rectangle())   // .plain só clica em pixels opacos
        }
        .buttonStyle(.plain)
        .disabled(killing)
        .onHover { hovering = $0 }
        .help("Kill \(name)")
        .accessibilityLabel("Kill \(name)")
    }
}

struct ActionButton: View {
    let title: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            CapsLabel(title, color: hovering ? Theme.textPrimary : Theme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.border, lineWidth: 1))
                .contentShape(Rectangle())   // .plain só clica em pixels opacos
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
