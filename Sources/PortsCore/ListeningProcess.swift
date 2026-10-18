import Foundation

public struct Container: Hashable, Sendable {
    public let id: String       // ID curto do docker ps
    public let name: String     // "supabase_db_yt-city"
    public let image: String    // "public.ecr.aws/supabase/postgres:17.11.0.004"
    /// Containers sem porta publicada do mesmo projeto compose (ex: auth/rest do Supabase): param junto com o grupo.
    public var stackIDs: [String] = []
}

/// Um processo (ou container Docker) ouvindo em uma ou mais portas TCP.
public struct ListeningProcess: Identifiable, Hashable, Sendable {
    /// Containers compartilham o PID do runtime do Docker, então o id não pode ser só o PID.
    public var id: String { container.map { "c:\($0.id)" } ?? "\(pid)" }
    public internal(set) var pid: Int32
    public internal(set) var name: String
    public internal(set) var ports: [UInt16]   // ordenado, sem duplicatas IPv4/IPv6
    public internal(set) var startedAt: Date
    public internal(set) var cpuPercent: Double
    public internal(set) var memoryBytes: UInt64
    public internal(set) var command: String
    public internal(set) var executablePath: String
    public internal(set) var cwd: String?
    public internal(set) var isSystem: Bool
    public internal(set) var project: Project? = nil   // nil quando não há cwd
    public internal(set) var kind: String? = nil       // "VITE", "NEXT"…; nil = usar `name`
    public internal(set) var container: Container? = nil
    /// Conexões TCP de entrada estabelecidas nas portas deste processo/container (aba com HMR, app no banco…).
    public internal(set) var inboundConnections: Int = 0

    public var title: String { kind ?? name }

    func with(ports: [UInt16]) -> Self {
        var copy = self
        copy.ports = ports
        return copy
    }

    /// Esquecido = **ocioso** há `threshold`: sem conexões de entrada desde `lastActive` (ou desde o start).
    public func isStale(now: Date = .now, threshold: TimeInterval, lastActive: Date? = nil) -> Bool {
        inboundConnections == 0 && now.timeIntervalSince(idleSince(lastActive: lastActive)) >= threshold
    }

    public func idleSince(lastActive: Date?) -> Date {
        max(lastActive ?? startedAt, startedAt)
    }
}
