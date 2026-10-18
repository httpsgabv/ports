public struct ProcessGroup: Identifiable, Sendable {
    public let id: String                  // project.root, ou "pid:<pid>" sem projeto
    public let project: Project?
    public let processes: [ListeningProcess]

    public var memoryBytes: UInt64 { processes.reduce(0) { $0 + $1.memoryBytes } }
    public var ports: [UInt16] { processes.flatMap(\.ports).sorted() }
}

/// Agrupa pela raiz do projeto mantendo a ordem de entrada (já ordenada pela menor porta).
public func groupByProject(_ processes: [ListeningProcess]) -> [ProcessGroup] {
    var order: [String] = []
    var members: [String: [ListeningProcess]] = [:]
    for p in processes {
        let key = p.project?.root ?? "pid:\(p.pid)"
        if members[key] == nil { order.append(key) }
        members[key, default: []].append(p)
    }
    return order.map { ProcessGroup(id: $0, project: members[$0]![0].project, processes: members[$0]!) }
}
