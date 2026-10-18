import AppKit

struct Editor: Identifiable, Hashable {
    let name: String
    let bundleID: String
    var id: String { bundleID }
}

/// Ordem = prioridade do padrão (o primeiro instalado ganha).
private let knownEditors = [
    Editor(name: "Cursor", bundleID: "com.todesktop.230313mzl4w4u92"),
    Editor(name: "Visual Studio Code", bundleID: "com.microsoft.VSCode"),
    Editor(name: "Zed", bundleID: "dev.zed.Zed"),
    Editor(name: "Windsurf", bundleID: "com.exafunction.windsurf"),
    Editor(name: "Sublime Text", bundleID: "com.sublimetext.4"),
    Editor(name: "Xcode", bundleID: "com.apple.dt.Xcode"),
]

@MainActor
private func appURL(_ editor: Editor) -> URL? {
    // fallback por nome: o bundle ID do Cursor já mudou entre versões
    NSWorkspace.shared.urlForApplication(withBundleIdentifier: editor.bundleID)
        ?? [URL(fileURLWithPath: "/Applications/\(editor.name).app")].first { FileManager.default.fileExists(atPath: $0.path) }
}

@MainActor
func installedEditors() -> [Editor] {
    knownEditors.filter { appURL($0) != nil }
}

@MainActor
func open(_ path: String, in editor: Editor) {
    guard let app = appURL(editor) else { return }
    NSWorkspace.shared.open([URL(fileURLWithPath: path)], withApplicationAt: app, configuration: NSWorkspace.OpenConfiguration())
}
