import Foundation

struct DockerContainer: Equatable {
    let id: String
    let name: String
    let image: String
    let hostPorts: Set<UInt16>
    let createdAt: Date?
    let composeProject: String?
    let workdir: String?   // compose working_dir, senão o workdir da CLI do Supabase
}

private let runtimeNames: Set<String> = ["com.docker.backend", "OrbStack Helper", "limactl"]

/// Pelo nome do `lsof -Fc` (vem completo): dono das portas publicadas pelos containers.
func isContainerRuntime(_ name: String) -> Bool { runtimeNames.contains(name) }

let dockerPsFormat = #"{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.CreatedAt}}\t{{.Label "com.docker.compose.project"}}\t{{.Label "com.docker.compose.project.working_dir"}}\t{{.Label "com.supabase.cli.workdir"}}"#

func dockerBinary(home: String = NSHomeDirectory()) -> String? {
    ["/usr/local/bin/docker", "/opt/homebrew/bin/docker", "\(home)/.orbstack/bin/docker"]
        .first { FileManager.default.isExecutableFile(atPath: $0) }
}

func parseDockerPs(_ out: String) -> [DockerContainer] {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"

    return out.split(separator: "\n").compactMap { line in
        let f = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
        guard f.count >= 8 else { return nil }
        let nonEmpty = { (s: String) in s.isEmpty ? nil : s }
        return DockerContainer(
            id: f[0],
            name: f[1],
            image: f[2],
            hostPorts: parseHostPorts(f[3]),
            createdAt: formatter.date(from: f[4].split(separator: " ").prefix(3).joined(separator: " ")),
            composeProject: nonEmpty(f[5]),
            workdir: nonEmpty(f[6]) ?? nonEmpty(f[7])
        )
    }
}

/// `0.0.0.0:8795->80/tcp, [::]:8795->80/tcp, 127.0.0.1:8000-8001->8000-8001/tcp, 6379/tcp`
private func parseHostPorts(_ field: String) -> Set<UInt16> {
    var ports: Set<UInt16> = []
    for mapping in field.split(separator: ",") {
        guard let arrow = mapping.range(of: "->"),
              let colon = mapping[..<arrow.lowerBound].lastIndex(of: ":") else { continue }   // sem "->": não publicada
        let spec = mapping[mapping.index(after: colon)..<arrow.lowerBound]
        let bounds = spec.split(separator: "-").compactMap { UInt16($0) }
        if let lo = bounds.first, let hi = bounds.last, lo <= hi { ports.formUnion(lo...hi) }
    }
    return ports
}

/// `public.ecr.aws/supabase/postgres:17` → `POSTGRES`
func imageKind(_ image: String) -> String {
    let noDigest = image.split(separator: "@").first.map(String.init) ?? image
    let last = noDigest.split(separator: "/").last.map(String.init) ?? noDigest
    return (last.split(separator: ":").first.map(String.init) ?? last).uppercased()
}

/// Troca as portas do runtime por uma entrada por container; portas sem container ficam no runtime.
func expandContainers(
    _ processes: [ListeningProcess],
    _ containers: [DockerContainer],
    resolve: (String) -> Project = { resolveProject(cwd: $0) }
) -> [ListeningProcess] {
    var out: [ListeningProcess] = []
    for p in processes {
        guard isContainerRuntime(p.name) else { out.append(p); continue }
        var left = Set(p.ports)
        for c in containers {
            let mine = left.intersection(c.hostPorts)
            guard !mine.isEmpty else { continue }
            left.subtract(mine)
            var entry = p.with(ports: mine.sorted())
            entry.container = Container(id: c.id, name: c.name, image: c.image)
            entry.kind = imageKind(c.image)
            entry.startedAt = c.createdAt ?? p.startedAt
            entry.cpuPercent = 0
            entry.memoryBytes = 0   // docker stats custa ~1-2s; fora de escopo
            entry.command = "\(c.name) · \(c.image)"
            entry.cwd = c.workdir
            entry.project = c.workdir.map(resolve)
            entry.isSystem = false
            out.append(entry)
        }
        if !left.isEmpty { out.append(p.with(ports: left.sorted())) }
    }
    return out.sortedByLowestPort()
}

extension ListeningProcess {
    /// Entrada do runtime reconstruída a partir de um container, para o `scan(reusing:)` não repetir `ps` no PID do runtime.
    // ponytail: startedAt/cpu/mem do runtime se perdem quando todas as portas são de containers; só aparecem com showSystem e portas sobrando
    var runtimeBase: ListeningProcess {
        guard container != nil else { return self }
        var base = self
        base.container = nil
        base.kind = nil
        base.project = nil
        base.cwd = nil
        base.isSystem = isSystemPath(executablePath)
        return base
    }
}

/// `docker ps` só quando há runtime escutando. Docker ausente, parado ou travado → lista sem mudança.
func withContainers(_ processes: [ListeningProcess]) async -> [ListeningProcess] {
    guard processes.contains(where: { isContainerRuntime($0.name) }),
          let docker = dockerBinary(),
          let out = try? await run(docker, ["ps", "--format", dockerPsFormat], okStatuses: [0], timeout: .seconds(2))
    else { return processes }
    return expandContainers(processes, parseDockerPs(out))
}

func stopContainer(_ container: Container) async -> KillResult {
    guard let docker = dockerBinary() else { return .failed("docker not found") }
    do {
        _ = try await run(docker, ["stop", container.id], okStatuses: [0], timeout: .seconds(20))
        return .terminated
    } catch {
        return .failed(error.localizedDescription)
    }
}
