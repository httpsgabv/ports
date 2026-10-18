import Foundation

/// Processos do usuário atual em TCP LISTEN, ordenados pela menor porta.
// ponytail: 4 spawns por scan (~50-100ms); libproc evita os spawns se o custo incomodar
public func scan() async throws -> [ListeningProcess] {
    let listen = parseLsofListen(try await run("/usr/sbin/lsof", ["-nP", "-iTCP", "-sTCP:LISTEN", "-Fpcn"]))
    guard !listen.isEmpty else { return [] }

    let pids = listen.keys.map(String.init).joined(separator: ",")
    async let details = run("/bin/ps", ["-o", "pid=,lstart=,%cpu=,rss=,comm=", "-p", pids])
    async let commands = run("/bin/ps", ["-o", "pid=,command=", "-p", pids])
    async let cwds = run("/usr/sbin/lsof", ["-a", "-d", "cwd", "-p", pids, "-Fpn"])

    return merge(
        listen: listen,
        details: parsePsDetails(try await details),
        commands: parsePsCommand(try await commands),
        cwds: parseLsofCwd(try await cwds)
    )
}
