import Darwin
import Foundation
import Testing
@testable import PortsCore

@Suite struct KillerTests {
    @Test func gracefulTerminate() async throws {
        let p = try await spawnDetached("/bin/sleep 60")
        defer { Darwin.kill(p.pid, SIGKILL) }
        #expect(await terminate(p) == .terminated)
        #expect(!isAlive(p.pid))
    }

    @Test func escalatesToSigkillWhenTermIgnored() async throws {
        let p = try await spawnDetached(#"/bin/sh -c 'trap "" TERM; exec /bin/sleep 60'"#)
        defer { Darwin.kill(p.pid, SIGKILL) }
        #expect(await terminate(p, grace: .milliseconds(300)) == .killed)
        #expect(!isAlive(p.pid))
    }

    @Test func alreadyGone() async throws {
        let p = try await spawnDetached("/bin/sleep 60")
        Darwin.kill(p.pid, SIGKILL)
        while isAlive(p.pid) { try await Task.sleep(for: .milliseconds(20)) }
        #expect(await terminate(p) == .alreadyGone)
    }

    @Test func pidReusedSendsNoSignal() async throws {
        let real = try await spawnDetached("/bin/sleep 60")
        defer { Darwin.kill(real.pid, SIGKILL) }
        let stale = fake(pid: real.pid, startedAt: real.startedAt.addingTimeInterval(-3600))
        #expect(await terminate(stale) == .pidReused)
        #expect(isAlive(real.pid))
    }

    @Test(arguments: [Int32(1), getpid()])
    func refusesInitAndSelf(pid: Int32) async {
        #expect(await terminate(fake(pid: pid, startedAt: .now)) == .failed("refused"))
    }

    // Desanexado via `sh &`: vira filho do launchd, como um dev server real (sem zumbi no teste).
    private func spawnDetached(_ cmd: String) async throws -> ListeningProcess {
        let out = try await run("/bin/sh", ["-c", "\(cmd) >/dev/null 2>&1 & echo $!"])
        let pid = try #require(Int32(out.trimmingCharacters(in: .whitespacesAndNewlines)))
        try await Task.sleep(for: .milliseconds(200))   // deixa o `trap` ser instalado
        let started = try #require(await startTime(of: pid))
        return fake(pid: pid, startedAt: started)
    }

    private func fake(pid: Int32, startedAt: Date) -> ListeningProcess {
        ListeningProcess(pid: pid, name: "test", ports: [], startedAt: startedAt, cpuPercent: 0,
                         memoryBytes: 0, command: "", executablePath: "", cwd: nil, isSystem: false)
    }
}
