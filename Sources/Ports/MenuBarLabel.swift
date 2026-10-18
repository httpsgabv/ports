import AppKit
import SwiftUI

/// Símbolo + contador. A menu bar força labels SwiftUI a monocromático,
/// então renderizamos um NSImage: template (segue a menu bar) ou âmbar quando há processo stale.
struct MenuBarLabel: View {
    let count: Int
    let stale: Bool

    var body: some View {
        Image(nsImage: image)
            .accessibilityLabel("\(count) open ports")
    }

    private var image: NSImage {
        let content = HStack(spacing: 3) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 13, weight: .light))
            if count > 0 {
                Text("\(count)").font(Theme.mono(12, .medium))
            }
        }
        .foregroundStyle(stale ? Theme.stale : .black)
        .opacity(count == 0 ? 0.5 : 1)

        let renderer = ImageRenderer(content: content)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        let image = renderer.nsImage ?? NSImage()
        image.isTemplate = !stale
        return image
    }
}
