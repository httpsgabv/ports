import Foundation
import Testing
@testable import PortsCore

@Suite struct GroupingTests {
    private func p(_ pid: Int32, _ port: UInt16, root: String?, mem: UInt64 = 1) -> ListeningProcess {
        ListeningProcess(pid: pid, name: "node", ports: [port], startedAt: .now, cpuPercent: 0, memoryBytes: mem,
                         command: "", executablePath: "node", cwd: root, isSystem: false,
                         project: root.map { Project(root: $0, name: ($0 as NSString).lastPathComponent) })
    }

    @Test func groupsByProjectRootInPortOrder() {
        let groups = groupByProject([
            p(1, 3000, root: "/dev/site"),
            p(2, 5173, root: "/dev/yt-city", mem: 10),
            p(3, 5174, root: "/dev/yt-city", mem: 20),
            p(4, 8000, root: nil),
            p(5, 9000, root: "/dev/yt-city", mem: 30),
        ])
        #expect(groups.map(\.id) == ["/dev/site", "/dev/yt-city", "pid:4"])
        let yt = groups[1]
        #expect(yt.processes.map(\.pid) == [2, 3, 5])
        #expect(yt.project?.name == "yt-city")
        #expect(yt.memoryBytes == 60)
        #expect(yt.ports == [5173, 5174, 9000])
        #expect(groups[2].project == nil)
    }

    @Test func mergeFillsKindAndProject() {
        let r = merge(
            listen: parseLsofListen(Fixture.lsofListen),
            details: parsePsDetails(Fixture.psDetails),
            commands: parsePsCommand(Fixture.psCommand),
            cwds: parseLsofCwd(Fixture.lsofCwd),
            resolve: { Project(root: $0, name: "stub") }
        )
        let node = r.first { $0.pid == 47102 }
        #expect(node?.kind == "VITE")
        #expect(node?.title == "VITE")
        #expect(node?.project == Project(root: "/Users/gabriel/Documents/dev/yt-city", name: "stub"))
        #expect(r.first { $0.pid == 627 }?.project == nil)   // cwd "/" → sem projeto
    }

    @Test func reusedProcessKeepsIdentityWhenPortsChange() {
        let base = p(1, 3000, root: "/dev/site")
        let moved = base.with(ports: [3000, 3001])
        #expect(moved.project == base.project)
        #expect(moved.ports == [3000, 3001])
    }
}
