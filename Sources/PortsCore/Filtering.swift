public func visible(_ processes: [ListeningProcess], showSystem: Bool) -> [ListeningProcess] {
    showSystem ? processes : processes.filter { !$0.isSystem }
}

/// Total do header: chame com a lista já filtrada (visíveis e não esperados). Containers somam 0 (sem dados).
public func totalMemory(_ processes: [ListeningProcess]) -> UInt64 {
    processes.reduce(0) { $0 + $1.memoryBytes }
}
