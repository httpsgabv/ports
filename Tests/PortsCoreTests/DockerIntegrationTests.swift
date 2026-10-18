import Foundation
import Testing
@testable import PortsCore

/// Precisa do Docker rodando e da imagem `caddy:2-alpine` local (sem download). Pula caso contrário.
@Suite(.serialized) struct DockerIntegrationTests {
    static var dockerReady: Bool {
        guard let docker = dockerBinary() else { return false }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: docker)
        p.arguments = ["image", "inspect", "caddy:2-alpine"]
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        guard (try? p.run()) != nil else { return false }
        p.waitUntilExit()
        return p.terminationStatus == 0
    }

    @Test(.enabled(if: dockerReady)) func scanFindsContainerAndStopStopsIt() async throws {
        let docker = try #require(dockerBinary())
        let name = "ports-it-\(UInt32.random(in: 0...UInt32.max))"
        _ = try await run(docker, ["run", "-d", "--rm", "--name", name, "-p", "127.0.0.1:8797:80", "caddy:2-alpine"], okStatuses: [0])
        defer { _ = try? Process.run(URL(fileURLWithPath: docker), arguments: ["rm", "-f", name]) }
        try await Task.sleep(for: .seconds(1))

        let first = try await scan()
        let c = try #require(first.first { $0.container?.name == name })
        #expect(c.ports == [8797])
        #expect(c.kind == "CADDY")
        #expect(!c.isSystem)

        // tick seguinte reusando a lista: o container continua lá (runtime reconstruído)
        let second = try await scan(reusing: first)
        #expect(second.contains { $0.container?.name == name })

        #expect(await terminate(c) == .terminated)
        let ps = try await run(docker, ["ps", "--filter", "name=\(name)", "--format", "{{.Names}}"], okStatuses: [0])
        #expect(ps.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
