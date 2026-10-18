import SwiftUI

enum Theme {
    static let bg = Color(hex: 0x000000)
    static let surface = Color(hex: 0x0A0A0A)
    static let border = Color(hex: 0x1F1F1F)
    static let textPrimary = Color(hex: 0xEDEDED)
    static let textSecondary = Color(hex: 0x888888)
    static let textTertiary = Color(hex: 0x555555)
    static let live = Color(hex: 0x00E676)
    static let stale = Color(hex: 0xF5A623)
    static let danger = Color(hex: 0xFF4D4D)

    static let width: CGFloat = 380
    static let radius: CGFloat = 6
    static let hairline: CGFloat = 0.5

    static func mono(_ size: CGFloat = 12, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static func sans(_ size: CGFloat = 13, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}

/// CAPS 10pt, tracking +1, tertiary.
struct CapsLabel: View {
    let text: String
    var color: Color = Theme.textTertiary

    init(_ text: String, color: Color = Theme.textTertiary) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(Theme.mono(10, .medium))
            .tracking(1)
            .foregroundStyle(color)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
