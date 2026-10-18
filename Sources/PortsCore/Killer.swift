import Darwin
import Foundation

public enum KillResult: Equatable, Sendable {
    case terminated        // morreu com SIGTERM
    case killed            // precisou de SIGKILL
    case alreadyGone
    case pidReused         // PID agora é outro processo: nenhum sinal enviado
    case failed(String)
}

/// SIGTERM, espera `grace`, depois SIGKILL. Só sinaliza se o pid ainda é o mesmo processo listado.
public func terminate(_ process: ListeningProcess, grace: Duration = .seconds(3)) async -> KillResult {
    let pid = process.pid
    guard pid > 1, pid != getpid() else { return .failed("refused") }
    guard let started = await startTime(of: pid) else { return .alreadyGone }
    guard abs(started.timeIntervalSince(process.startedAt)) <= 1 else { return .pidReused }

    if Darwin.kill(pid, SIGTERM) != 0 {
        switch errno {
        case ESRCH: return .alreadyGone
        case EPERM: return .failed("permission denied")
        default: return .failed(String(cString: strerror(errno)))
        }
    }
    if await waitForExit(pid, timeout: grace) { return .terminated }

    Darwin.kill(pid, SIGKILL)
    return await waitForExit(pid, timeout: .seconds(1)) ? .killed : .failed("still running")
}

func startTime(of pid: Int32) async -> Date? {
    let out = try? await run("/bin/ps", ["-o", "pid=,lstart=,%cpu=,rss=,comm=", "-p", String(pid)])
    return out.flatMap { parsePsDetails($0)[pid]?.startedAt }
}

func isAlive(_ pid: Int32) -> Bool {
    Darwin.kill(pid, 0) == 0 || errno == EPERM
}

private func waitForExit(_ pid: Int32, timeout: Duration) async -> Bool {
    let deadline = ContinuousClock.now + timeout
    while isAlive(pid) {
        guard ContinuousClock.now < deadline else { return false }
        try? await Task.sleep(for: .milliseconds(100))
    }
    return true
}
