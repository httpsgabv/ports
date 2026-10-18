import Foundation

/// Um processo ouvindo em uma ou mais portas TCP.
public struct ListeningProcess: Identifiable, Hashable, Sendable {
    public var id: Int32 { pid }
    public let pid: Int32
    public let name: String
    public internal(set) var ports: [UInt16]   // ordenado, sem duplicatas IPv4/IPv6
    public let startedAt: Date
    public let cpuPercent: Double
    public let memoryBytes: UInt64
    public let command: String
    public let executablePath: String
    public let cwd: String?
    public let isSystem: Bool
    public var project: Project? = nil   // nil quando não há cwd
    public var kind: String? = nil       // "VITE", "NEXT"…; nil = usar `name`

    public var title: String { kind ?? name }

    func with(ports: [UInt16]) -> Self {
        var copy = self
        copy.ports = ports
        return copy
    }

    public func isStale(now: Date = .now, threshold: TimeInterval) -> Bool {
        now.timeIntervalSince(startedAt) >= threshold
    }
}
