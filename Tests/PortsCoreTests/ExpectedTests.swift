import Foundation
import Testing
@testable import PortsCore

@Suite struct ExpectedTests {
    private func p(_ pid: Int32, name: String = "node", kind: String? = nil, cwd: String? = nil,
                   root: String? = nil, exe: String = "node") -> ListeningProcess {
        ListeningProcess(pid: pid, name: name, ports: [UInt16(3000 + pid)], startedAt: .now, cpuPercent: 0,
                         memoryBytes: 0, command: "", executablePath: exe, cwd: cwd, isSystem: false,
                         project: root.map { Project(root: $0, name: "x") }, kind: kind)
    }

    @Test func keyPrefersKindAndProjectRoot() {
        #expect(expectationKey(p(1, kind: "VITE", cwd: "/r/apps/web", root: "/r")) == "VITE@/r")
    }

    @Test func keyFallsBackToCwdThenExecutable() {
        #expect(expectationKey(p(1, name: "postgres", cwd: "/opt/homebrew/var/pg")) == "postgres@/opt/homebrew/var/pg")
        #expect(expectationKey(p(1, name: "agent", exe: "/usr/local/bin/agent")) == "agent@/usr/local/bin/agent")
    }

    @Test func keyIgnoresPidAndPort() {
        let a = p(1, kind: "POSTGRES", cwd: "/data", root: "/data")
        let b = p(99, kind: "POSTGRES", cwd: "/data", root: "/data")   // reiniciado: outro pid e porta
        #expect(expectationKey(a) == expectationKey(b))
    }

    @Test func splitKeepsOrder() {
        let all = [p(1, kind: "VITE", root: "/a"), p(2, kind: "POSTGRES", root: "/db"), p(3, kind: "NEXT", root: "/b")]
        let (active, expected) = split(all, expected: ["POSTGRES@/db"])
        #expect(active.map(\.pid) == [1, 3])
        #expect(expected.map(\.pid) == [2])
    }
}
