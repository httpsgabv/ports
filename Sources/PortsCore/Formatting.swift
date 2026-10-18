import Foundation

/// `59s`, `12m`, `3h 05m`, `2d 4h`
public func formatUptime(_ seconds: TimeInterval) -> String {
    let s = max(0, Int(seconds))
    switch s {
    case ..<60: return "\(s)s"
    case ..<3600: return "\(s / 60)m"
    case ..<86400: return "\(s / 3600)h " + String(format: "%02dm", s % 3600 / 60)
    default: return "\(s / 86400)d \(s % 86400 / 3600)h"
    }
}

/// `512 KB`, `16 MB`, `1.2 GB` (base 1024)
public func formatBytes(_ bytes: UInt64) -> String {
    let kb = bytes / 1024
    switch kb {
    case ..<1024: return "\(kb) KB"
    case ..<(1024 * 1024): return "\(kb / 1024) MB"
    default: return String(format: "%.1f GB", Double(bytes) / 1_073_741_824)
    }
}

/// `0.3%`; acima de 100% (multi-core) sem casa decimal.
public func formatCPU(_ percent: Double) -> String {
    percent >= 100 ? String(format: "%.0f%%", percent) : String(format: "%.1f%%", percent)
}

public func abbreviateHome(_ path: String, home: String = NSHomeDirectory()) -> String {
    if path == home { return "~" }
    return path.hasPrefix(home + "/") ? "~" + path.dropFirst(home.count) : path
}
