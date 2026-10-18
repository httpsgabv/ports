import Foundation
import Testing
@testable import PortsCore

@Suite struct DockerTests {
    // Saída real do `docker ps --format` (Docker 28.4), campos separados por TAB.
    static let ps = [
        "2c0d08eb1254\tports-probe\tcaddy:2-alpine\t0.0.0.0:8795->80/tcp, [::]:8795->80/tcp, 127.0.0.1:8796->443/tcp\t2026-10-17 23:03:18 -0300 -03\t\t\t",
        "9f1e2d3c4b5a\tsupabase_db_yt-city\tpublic.ecr.aws/supabase/postgres:17.11.0.004\t0.0.0.0:54322->5432/tcp\t2026-10-17 21:00:00 -0300 -03\tyt-city\t\t/Users/gabriel/Documents/dev/yt-city",
        "aaaaaaaaaaaa\tapi-web-1\tnode:22\t127.0.0.1:8000-8001->8000-8001/tcp\t2026-10-17 20:00:00 -0300 -03\tapi\t/Users/gabriel/dev/api\t",
        "bbbbbbbbbbbb\tworker\tredis:7\t6379/tcp\t2026-10-17 20:00:00 -0300 -03\t\t\t",
        "cccccccccccc\tapi-queue-1\tredis:7\t6379/tcp\t2026-10-17 20:00:00 -0300 -03\tapi\t/Users/gabriel/dev/api\t",
    ].joined(separator: "\n") + "\n"

    @Test func parsesPortsLabelsAndDates() throws {
        let cs = parseDockerPs(Self.ps)
        #expect(cs.count == 5)

        let caddy = cs[0]
        #expect(caddy.id == "2c0d08eb1254")
        #expect(caddy.hostPorts == [8795, 8796])   // v4+v6 deduped, várias portas
        #expect(caddy.workdir == nil)
        let created = try #require(caddy.createdAt)
        #expect(created == ISO8601DateFormatter().date(from: "2026-10-18T02:03:18Z"))

        #expect(cs[1].workdir == "/Users/gabriel/Documents/dev/yt-city")   // label do supabase
        #expect(cs[1].composeProject == "yt-city")
        #expect(cs[2].hostPorts == [8000, 8001])   // faixa
        #expect(cs[2].workdir == "/Users/gabriel/dev/api")                 // working_dir do compose
        #expect(cs[3].hostPorts.isEmpty)           // porta não publicada
    }

    @Test(arguments: [
        ("caddy:2-alpine", "CADDY"),
        ("public.ecr.aws/supabase/postgres:17.11.0.004", "POSTGRES"),
        ("redis", "REDIS"),
        ("localhost:5000/team/api@sha256:abc", "API"),
    ])
    func kindFromImage(image: String, kind: String) {
        #expect(imageKind(image) == kind)
    }

    @Test func runtimeNames() {
        #expect(isContainerRuntime("com.docker.backend"))
        #expect(isContainerRuntime("OrbStack Helper"))
        #expect(!isContainerRuntime("node"))
    }

    private var runtime: ListeningProcess {
        ListeningProcess(pid: 1463, name: "com.docker.backend", ports: [8795, 8796, 54322, 60000],
                         startedAt: .distantPast, cpuPercent: 3, memoryBytes: 999, command: "backend",
                         executablePath: "/Applications/Docker.app/Contents/MacOS/com.docker.backend",
                         cwd: nil, isSystem: true)
    }

    @Test func expandsRuntimeIntoContainersAndKeepsLeftoverPorts() throws {
        let node = ListeningProcess(pid: 10, name: "node", ports: [5173], startedAt: .now, cpuPercent: 0,
                                    memoryBytes: 1, command: "", executablePath: "node", cwd: nil, isSystem: false)
        let out = expandContainers([node, runtime], parseDockerPs(Self.ps), resolve: { Project(root: $0, name: "stub") })

        #expect(out.map(\.id) == ["10", "c:2c0d08eb1254", "c:9f1e2d3c4b5a", "1463"])   // ordem por menor porta
        let caddy = out[1]
        #expect(caddy.pid == 1463)
        #expect(caddy.ports == [8795, 8796])
        #expect(caddy.kind == "CADDY")
        #expect(caddy.isSystem == false)
        #expect(caddy.memoryBytes == 0)
        #expect(caddy.container?.name == "ports-probe")
        #expect(out[2].project == Project(root: "/Users/gabriel/Documents/dev/yt-city", name: "stub"))
        #expect(out[2].cwd == "/Users/gabriel/Documents/dev/yt-city")
        let leftover = out[3]
        #expect(leftover.ports == [60000])
        #expect(leftover.isSystem && leftover.container == nil)
    }

    @Test func publishedContainersCarryTheirStacksInternalContainers() throws {
        let runtime = ListeningProcess(pid: 1463, name: "com.docker.backend", ports: [8000, 8001, 8795], startedAt: .distantPast,
                                       cpuPercent: 0, memoryBytes: 0, command: "", executablePath: "x", cwd: nil, isSystem: true)
        let out = expandContainers([runtime], parseDockerPs(Self.ps), resolve: { Project(root: $0, name: "api") })
        let web = try #require(out.first { $0.container?.name == "api-web-1" })
        #expect(web.container?.stackIDs == ["cccccccccccc"])        // api-queue-1: mesmo compose, sem porta
        let caddy = try #require(out.first { $0.container?.name == "ports-probe" })
        #expect(caddy.container?.stackIDs == [])                     // sem compose: nada
        // "worker" (sem porta, sem compose) não entra em stack nenhuma

        let group = try #require(groupByProject(out).first { $0.project?.name == "api" })
        #expect(group.internalContainerIDs == ["cccccccccccc"])
    }

    @Test func exposureIsPerEntryPorts() throws {
        // runtime: 8795 publicado em 0.0.0.0, 8796 só em 127.0.0.1
        let listen = parseLsofListen("p1463\nccom.docker.backend\nn*:8795\nn127.0.0.1:8796\nn*:54322\n")
        let runtime = ListeningProcess(pid: 1463, name: "com.docker.backend", ports: [8795, 8796, 54322], startedAt: .distantPast,
                                       cpuPercent: 0, memoryBytes: 0, command: "", executablePath: "x", cwd: nil, isSystem: true)
        let out = withSocketState(expandContainers([runtime], parseDockerPs(Self.ps), resolve: { Project(root: $0, name: "x") }), listen)
        #expect(out.first { $0.container?.name == "ports-probe" }?.isExposed == true)   // 8795 exposta
        #expect(out.first { $0.container?.name == "supabase_db_yt-city" }?.isExposed == true)
    }

    @Test func containerKeyUsesName() throws {
        let c = try #require(expandContainers([runtime], parseDockerPs(Self.ps), resolve: { Project(root: $0, name: "x") })
            .first { $0.container?.name == "ports-probe" })
        #expect(expectationKey(c) == "container@ports-probe")
    }

    @Test func runtimeBaseRestoresRuntimeForReuse() throws {
        let c = try #require(expandContainers([runtime], parseDockerPs(Self.ps), resolve: { Project(root: $0, name: "x") }).first)
        let base = c.runtimeBase
        #expect(base.container == nil && base.kind == nil && base.project == nil && base.cwd == nil)
        #expect(base.isSystem)
        #expect(base.id == "1463")
    }
}
