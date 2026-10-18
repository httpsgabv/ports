import Darwin
import Foundation
import Testing
@testable import PortsCore

@Suite struct ScannerIntegrationTests {
    @Test func scanFindsOwnListeningSocket() async throws {
        let (fd, port) = try listenOnEphemeralPort()
        defer { close(fd) }

        let processes = try await scan()

        let me = try #require(processes.first { $0.pid == getpid() })
        #expect(me.ports.contains(port))
        #expect(me.cwd == FileManager.default.currentDirectoryPath)
        #expect(me.startedAt < .now)
        #expect(!me.command.isEmpty)
        // Sem limite de tempo aqui: wall-clock falha com a máquina carregada. A meta (< 300ms) fica na spec 01.
    }

    @Test func scanReusesDetailsOfKnownPidsButRefreshesPorts() async throws {
        let (fd, port) = try listenOnEphemeralPort()
        defer { close(fd) }
        let known = ListeningProcess(pid: getpid(), name: "cached", ports: [1], startedAt: .distantPast,
                                     cpuPercent: 99, memoryBytes: 0, command: "cached", executablePath: "",
                                     cwd: nil, isSystem: false)

        let me = try #require(try await scan(reusing: [known]).first { $0.pid == getpid() })
        #expect(me.cpuPercent == 99)       // sem ps para pid conhecido
        #expect(me.ports.contains(port))   // portas sempre do lsof atual
    }

    @Test func countsInboundConnectionsThenDropsToZero() async throws {
        let (fd, port) = try listenOnEphemeralPort()
        defer { close(fd) }
        #expect(try await mine(port)?.inboundConnections == 0)

        let client = try connect(to: port)
        let accepted = accept(fd, nil, nil)          // o socket do lado servidor só existe após o accept
        try #require(accepted >= 0)
        let me = try #require(try await mine(port))
        #expect(me.inboundConnections == 1)          // o lado cliente (porta efêmera) não conta
        #expect(!me.ports.contains(try localPort(of: client)))   // a porta efêmera do cliente não vira porta
        // (não comparar `me.ports == [port]`: outros testes em paralelo abrem portas no mesmo processo)

        close(client)
        close(accepted)
        #expect(try await mine(port)?.inboundConnections == 0)
    }

    private func mine(_ port: UInt16) async throws -> ListeningProcess? {
        try await scan().first { $0.pid == getpid() && $0.ports.contains(port) }
    }

    private func localPort(of fd: Int32) throws -> UInt16 {
        var addr = sockaddr_in()
        var len = socklen_t(MemoryLayout<sockaddr_in>.size)
        let ok = withUnsafeMutablePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { getsockname(fd, $0, &len) == 0 }
        }
        try #require(ok)
        return UInt16(bigEndian: addr.sin_port)
    }

    private func connect(to port: UInt16) throws -> Int32 {
        let fd = socket(AF_INET, SOCK_STREAM, 0)
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_addr.s_addr = inet_addr("127.0.0.1")
        addr.sin_port = port.bigEndian
        let ok = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.connect(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) == 0
            }
        }
        try #require(ok)
        return fd
    }

    @Test func runTimesOut() async {
        let start = ContinuousClock.now
        await #expect(throws: ShellError.self) {
            try await run("/bin/sleep", ["5"], timeout: .milliseconds(200))
        }
        #expect(ContinuousClock.now - start < .seconds(1))
    }

    @Test func runPassesHomeForDocker() async throws {
        let home = try await run("/bin/sh", ["-c", "echo $HOME"])
        #expect(home.trimmingCharacters(in: .whitespacesAndNewlines) == NSHomeDirectory())
    }

    @Test func runThrowsForMissingBinary() async {
        await #expect(throws: ShellError.self) {
            try await run("/nonexistent/bin", [])
        }
    }

    private func listenOnEphemeralPort() throws -> (Int32, UInt16) {
        let fd = socket(AF_INET, SOCK_STREAM, 0)
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_addr.s_addr = inet_addr("127.0.0.1")
        addr.sin_port = 0
        var len = socklen_t(MemoryLayout<sockaddr_in>.size)
        let ok = withUnsafeMutablePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(fd, $0, len) == 0 && listen(fd, 1) == 0 && getsockname(fd, $0, &len) == 0
            }
        }
        try #require(ok)
        return (fd, UInt16(bigEndian: addr.sin_port))
    }
}
