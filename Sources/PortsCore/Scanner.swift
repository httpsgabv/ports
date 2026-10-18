import Foundation

/// Processos do usuário atual em TCP LISTEN, ordenados pela menor porta.
/// `reusing`: pids já conhecidos mantêm os detalhes (cpu, mem, cwd…) e só atualizam as portas,
/// evitando 3 spawns (~85ms de CPU) por tick quando ninguém está olhando.
// ponytail: ainda 1 spawn de lsof por tick (~34ms CPU); libproc zera isso se incomodar
public func scan(reusing previous: [ListeningProcess] = []) async throws -> [ListeningProcess] {
    let listen = parseLsofListen(try await run("/usr/sbin/lsof", ["-nP", "-iTCP", "-sTCP:LISTEN", "-Fpcn"]))
    guard !listen.isEmpty else { return [] }

    let known = Dictionary(previous.map { ($0.pid, $0) }, uniquingKeysWith: { a, _ in a })
    let reused = listen.compactMap { pid, l in known[pid]?.with(ports: l.ports.sorted()) }
    let fresh = listen.filter { known[$0.key] == nil }
    guard !fresh.isEmpty else { return reused.sortedByLowestPort() }

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
    return (reused + new).sortedByLowestPort()
}
