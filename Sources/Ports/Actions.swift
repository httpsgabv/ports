import AppKit

@MainActor
func openPort(_ port: UInt16) {
    if let url = URL(string: "http://localhost:\(port)") {
        NSWorkspace.shared.open(url)
    }
}

@MainActor
func revealInFinder(_ path: String) {
    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
}
