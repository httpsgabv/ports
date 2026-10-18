import Foundation

struct PsDetails: Equatable {
    let startedAt: Date
    let cpu: Double
    let rssBytes: UInt64
    let executablePath: String
}

typealias LsofEntry = (name: String, ports: Set<UInt16>, inbound: [UInt16], exposed: Set<UInt16>)

/// `lsof -nP -iTCP -sTCP:LISTEN,ESTABLISHED -Fpcn`. Linhas com `->` são conexões (`local->remoto`):
/// nunca viram portas; contam como entrada quando a porta local é uma das portas em LISTEN do pid.
/// Pids sem nenhum LISTEN (browser, nc) são descartados.
func parseLsofListen(_ out: String) -> [Int32: LsofEntry] {
    var result: [Int32: LsofEntry] = [:]
    var pid: Int32?
    func port(_ address: Substring) -> UInt16? {
        address.lastIndex(of: ":").flatMap { UInt16(address[address.index(after: $0)...]) }
    }
    for line in out.split(separator: "\n") {
        let value = line.dropFirst()
        switch line.first {
        case "p":
            pid = Int32(value)
            if let pid, result[pid] == nil { result[pid] = ("", [], [], []) }
        case "c":
            if let pid { result[pid]?.name = String(value) }
        case "n":
            guard let pid else { break }
            if let arrow = value.range(of: "->") {
                if let local = port(value[..<arrow.lowerBound]) { result[pid]?.inbound.append(local) }
            } else if let listening = port(value) {
                result[pid]?.ports.insert(listening)
                // `*`, `0.0.0.0`, `[::]`: aceita conexões de qualquer interface (Wi-Fi incluído)
                if ["*", "0.0.0.0", "[::]"].contains(value[..<value.lastIndex(of: ":")!]) {
                    result[pid]?.exposed.insert(listening)
                }
            }
        default:
            break
        }
    }
    return result.compactMapValues { entry in
        entry.ports.isEmpty ? nil : (entry.name, entry.ports, entry.inbound.filter(entry.ports.contains), entry.exposed)
    }
}

/// `ps -o pid=,lstart=,%cpu=,rss=,comm=` (com LC_ALL=C)
func parsePsDetails(_ out: String) -> [Int32: PsDetails] {
    let row = /^\s*(\d+)\s+(\w{3}\s+\w{3}\s+\d+\s+[\d:]{8}\s+\d{4})\s+([\d.]+)\s+(\d+)\s+(.+)$/
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "EEE MMM d HH:mm:ss yyyy"

    var result: [Int32: PsDetails] = [:]
    for line in out.split(separator: "\n") {
        guard let m = try? row.wholeMatch(in: line),
              let pid = Int32(m.1),
              let date = formatter.date(from: m.2.split(separator: " ").joined(separator: " ")),
              let cpu = Double(m.3),
              let rssKB = UInt64(m.4)
        else { continue }
        result[pid] = PsDetails(startedAt: date, cpu: cpu, rssBytes: rssKB * 1024, executablePath: String(m.5))
    }
    return result
}

/// `ps -o pid=,command=`
func parsePsCommand(_ out: String) -> [Int32: String] {
    var result: [Int32: String] = [:]
    for line in out.split(separator: "\n") {
        guard let m = try? /^\s*(\d+) (.*)$/.wholeMatch(in: line), let pid = Int32(m.1) else { continue }
        result[pid] = String(m.2)
    }
    return result
}

/// `lsof -a -d cwd -p <pids> -Fpn`. `/` vira ausente: não identifica projeto.
func parseLsofCwd(_ out: String) -> [Int32: String] {
    var result: [Int32: String] = [:]
    var pid: Int32?
    for line in out.split(separator: "\n") {
        switch line.first {
        case "p": pid = Int32(line.dropFirst())
        case "n": if let pid, line != "n/" { result[pid] = String(line.dropFirst()) }
        default: break
        }
    }
    return result
}

/// Daemons do sistema e apps GUI. `.app` dentro de `.framework/` (Python) ou `node_modules/` (Electron em dev) é runtime de projeto.
func isSystemPath(_ path: String) -> Bool {
    let isApp = path.contains(".app/Contents/") && !path.contains(".framework/") && !path.contains("/node_modules/")
    return isApp || ["/System/", "/usr/libexec/", "/usr/sbin/", "/sbin/"].contains { path.hasPrefix($0) }
}

func merge(
    listen: [Int32: LsofEntry],
    details: [Int32: PsDetails],
    commands: [Int32: String],
    cwds: [Int32: String],
    resolve: (String) -> Project = { resolveProject(cwd: $0) }
) -> [ListeningProcess] {
    listen.compactMap { pid, l -> ListeningProcess? in
        guard let d = details[pid], !l.ports.isEmpty else { return nil }   // morreu no meio do scan
        return ListeningProcess(
            pid: pid,
            name: l.name,
            ports: l.ports.sorted(),
            startedAt: d.startedAt,
            cpuPercent: d.cpu,
            memoryBytes: d.rssBytes,
            command: commands[pid] ?? d.executablePath,
            executablePath: d.executablePath,
            cwd: cwds[pid],
            isSystem: isSystemPath(d.executablePath),
            project: cwds[pid].map(resolve),
            kind: detectKind(command: commands[pid] ?? "", executable: d.executablePath)
        )
    }
    .sortedByLowestPort()
}

extension [ListeningProcess] {
    func sortedByLowestPort() -> Self {
        sorted { ($0.ports[0], $0.pid) < ($1.ports[0], $1.pid) }
    }
}
