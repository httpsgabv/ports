import Foundation

/// Um processo ouvindo em uma ou mais portas TCP.
public struct ListeningProcess: Identifiable, Hashable, Sendable {
    public var id: Int32 { pid }
    public let pid: Int32
    public let name: String
    public let ports: [UInt16]          // ordenado, sem duplicatas IPv4/IPv6
    public let startedAt: Date
    public let cpuPercent: Double
    public let memoryBytes: UInt64
    public let command: String
    public let executablePath: String
    public let cwd: String?
    public let isSystem: Bool

    func with(ports: [UInt16]) -> Self {
        Self(pid: pid, name: name, ports: ports, startedAt: startedAt, cpuPercent: cpuPercent,
             memoryBytes: memoryBytes, command: command, executablePath: executablePath, cwd: cwd, isSystem: isSystem)
    }

    public func isStale(now: Date = .now, threshold: TimeInterval) -> Bool {
        now.timeIntervalSince(startedAt) >= threshold
    }
}
