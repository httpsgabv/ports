import PortsCore
import ServiceManagement
import SwiftUI

struct PreferencesView: View {
    @Environment(PortStore.self) private var store
    let onBack: () -> Void

    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        @Bindable var store = store
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    CapsLabel("← Back", color: Theme.textSecondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
                Spacer()
                CapsLabel("Preferences")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            hairline

            row("Stale after") {
                HStack(spacing: 10) {
                    StepButton(symbol: "minus", disabled: store.staleHours <= 1) { store.staleHours -= 1 }
                    Text("\(store.staleHours)h")
                        .font(Theme.mono(12))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(minWidth: 28)
                    StepButton(symbol: "plus", disabled: store.staleHours >= 48) { store.staleHours += 1 }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Stale after \(store.staleHours) hours")
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment: store.staleHours = min(48, store.staleHours + 1)
                    case .decrement: store.staleHours = max(1, store.staleHours - 1)
                    @unknown default: break
                    }
                }
            }
            hairline
            row("Show system processes") {
                Toggle("", isOn: $store.showSystem).labelsHidden()
            }
            hairline
            row("Launch at login") {
                Toggle("", isOn: $launchAtLogin).labelsHidden()
            }
            if let loginError {
                Text(loginError)
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }
            hairline

            HStack {
                CapsLabel("Ports v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? PortsCore.version)")
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .toggleStyle(.switch)
        .controlSize(.mini)
        .tint(Theme.textPrimary)
        .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }
    }

    private func row<Control: View>(_ title: String, @ViewBuilder control: () -> Control) -> some View {
        HStack {
            CapsLabel(title, color: Theme.textSecondary)
            Spacer()
            control()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var hairline: some View {
        Rectangle().fill(Theme.border).frame(height: Theme.hairline)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        let service = SMAppService.mainApp
        guard enabled != (service.status == .enabled) else { return }   // já no estado (inclui o revert abaixo)
        loginError = nil
        do {
            if enabled { try service.register() } else { try service.unregister() }
        } catch {
            loginError = Bundle.main.bundlePath.hasPrefix("/Applications/")
                ? error.localizedDescription
                : "move app to /Applications"
        }
        if service.status == .requiresApproval {
            loginError = "approve in System Settings › Login Items"
            SMAppService.openSystemSettingsLoginItems()
        }
        launchAtLogin = service.status == .enabled
    }
}

private struct StepButton: View {
    let symbol: String
    let disabled: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .light))
                .foregroundStyle(disabled ? Theme.textTertiary : hovering ? Theme.textPrimary : Theme.textSecondary)
                .frame(width: 20, height: 20)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .onHover { hovering = $0 }
    }
}
