public func visible(_ processes: [ListeningProcess], showSystem: Bool) -> [ListeningProcess] {
    showSystem ? processes : processes.filter { !$0.isSystem }
}
