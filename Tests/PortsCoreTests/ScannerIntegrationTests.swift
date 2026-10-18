import Darwin
import Foundation
import Testing
@testable import PortsCore

@Suite struct ScannerIntegrationTests {
    @Test func scanFindsOwnListeningSocket() async throws {
        let (fd, port) = try listenOnEphemeralPort()
        defer { close(fd) }

        let start = ContinuousClock.now
        let processes = try await scan()
        let elapsed = ContinuousClock.now - start

        let me = try #require(processes.first { $0.pid == getpid() })
        #expect(me.ports.contains(port))
        #expect(me.cwd == FileManager.default.currentDirectoryPath)
        #expect(me.startedAt < .now)
        #expect(!me.command.isEmpty)
        #expect(elapsed < .milliseconds(300))
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
