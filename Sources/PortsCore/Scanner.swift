import Foundation

/// Processos do usuário atual em TCP LISTEN, ordenados pela menor porta.
/// `reusing`: pids já conhecidos mantêm os detalhes (cpu, mem, cwd…) e só atualizam as portas,
/// evitando 3 spawns (~85ms de CPU) por tick quando ninguém está olhando.
// ponytail: ainda 1 spawn de lsof por tick (~34ms CPU); libproc zera isso se incomodar
public func scan(reusing previous: [ListeningProcess] = []) async throws -> [ListeningProcess] {
    // LISTEN + ESTABLISHED no mesmo spawn: conexões de entrada = atividade (spec 09). ~+2ms de CPU.
    let listen = parseLsofListen(try await run("/usr/sbin/lsof", ["-nP", "-iTCP", "-sTCP:LISTEN,ESTABLISHED", "-Fpcn"]))
    guard !listen.isEmpty else { return [] }

    // Containers vêm do PID do runtime: reconstrói a entrada do runtime para não repetir `ps` nele.
    var known: [Int32: ListeningProcess] = [:]
    for p in previous where p.container != nil { known[p.pid] = known[p.pid] ?? p.runtimeBase }
    for p in previous where p.container == nil { known[p.pid] = p }
    let reused = listen.compactMap { pid, l in known[pid]?.with(ports: l.ports.sorted()) }
    let fresh = listen.filter { known[$0.key] == nil }
    guard !fresh.isEmpty else { return withConnections(await withContainers(reused.sortedByLowestPort()), listen) }

    let pids = fresh.keys.map(String.init).joined(separator: ",")
    async let details = run("/bin/ps", ["-o", "pid=,lstart=,%cpu=,rss=,comm=", "-p", pids])
    async let commands = run("/bin/ps", ["-o", "pid=,command=", "-p", pids])
    async let cwds = run("/usr/sbin/lsof", ["-a", "-d", "cwd", "-p", pids, "-Fpn"])

    let new = merge(
        listen: fresh,
        details: parsePsDetails(try await details),
        commands: parsePsCommand(try await commands),
        cwds: parseLsofCwd(try await cwds)
    )
    return withConnections(await withContainers((reused + new).sortedByLowestPort()), listen)
}

/// Depois da expansão em containers: cada entrada conta só as conexões das próprias portas.
func withConnections(_ processes: [ListeningProcess], _ listen: [Int32: LsofEntry]) -> [ListeningProcess] {
    processes.map { p in
        var copy = p
        copy.inboundConnections = listen[p.pid]?.inbound.filter(p.ports.contains).count ?? 0
        return copy
    }
}
