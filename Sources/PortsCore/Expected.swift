/// Identidade estável entre restarts (sem PID nem porta): `<kind ?? name>@<projeto ?? cwd ?? executável>`.
public func expectationKey(_ p: ListeningProcess) -> String {
    "\(p.title)@\(p.project?.root ?? p.cwd ?? p.executablePath)"
}

public func split(_ processes: [ListeningProcess], expected: Set<String>)
    -> (active: [ListeningProcess], expected: [ListeningProcess]) {
    var active: [ListeningProcess] = []
    var matched: [ListeningProcess] = []
    for p in processes {
        if expected.contains(expectationKey(p)) { matched.append(p) } else { active.append(p) }
    }
    return (active, matched)
}
