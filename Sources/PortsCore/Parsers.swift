import Foundation

struct PsDetails: Equatable {
    let startedAt: Date
    let cpu: Double
    let rssBytes: UInt64
    let executablePath: String
}

/// `lsof -nP -iTCP -sTCP:LISTEN -Fpcn`
func parseLsofListen(_ out: String) -> [Int32: (name: String, ports: Set<UInt16>)] {
    var result: [Int32: (name: String, ports: Set<UInt16>)] = [:]
    var pid: Int32?
    for line in out.split(separator: "\n") {
        let value = line.dropFirst()
        switch line.first {
        case "p":
            pid = Int32(value)
            if let pid, result[pid] == nil { result[pid] = ("", []) }
        case "c":
            if let pid { result[pid]?.name = String(value) }
        case "n":
            if let pid, let colon = value.lastIndex(of: ":"), let port = UInt16(value[value.index(after: colon)...]) {
                result[pid]?.ports.insert(port)
            }
        default:
            break
        }
    }
    return result
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
    listen: [Int32: (name: String, ports: Set<UInt16>)],
    details: [Int32: PsDetails],
    commands: [Int32: String],
    cwds: [Int32: String]
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
            isSystem: isSystemPath(d.executablePath)
        )
    }
    .sortedByLowestPort()
}

extension [ListeningProcess] {
    func sortedByLowestPort() -> Self {
        sorted { ($0.ports[0], $0.pid) < ($1.ports[0], $1.pid) }
    }
}
