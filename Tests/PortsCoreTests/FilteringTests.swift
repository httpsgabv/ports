import Foundation
import Testing
@testable import PortsCore

@Suite struct FilteringTests {
    let all = merge(
        listen: parseLsofListen(Fixture.lsofListen),
        details: parsePsDetails(Fixture.psDetails),
        commands: parsePsCommand(Fixture.psCommand),
        cwds: parseLsofCwd(Fixture.lsofCwd)
    )

    @Test func hidesSystemByDefault() {
        #expect(visible(all, showSystem: false).map(\.name) == ["node"])
    }

    @Test func showSystemKeepsEverythingInOrder() {
        #expect(visible(all, showSystem: true) == all)
    }

    @Test(arguments: [
        (7199.0, false),   // logo abaixo de 2h
        (7200.0, true),    // exatamente no limite
        (90000.0, true),
    ])
    func staleBoundary(age: TimeInterval, expected: Bool) throws {
        let node = try #require(all.first { $0.name == "node" })
        let now = node.startedAt.addingTimeInterval(age)
        #expect(node.isStale(now: now, threshold: 2 * 3600) == expected)
    }

    @Test func activeProcessIsNeverStale() throws {
        var node = try #require(all.first { $0.name == "node" })
        node.inboundConnections = 1
        #expect(!node.isStale(now: node.startedAt.addingTimeInterval(90_000), threshold: 7200))
    }

    @Test func idleCountsFromLastActivityNotFromStart() throws {
        let node = try #require(all.first { $0.name == "node" })
        let lastActive = node.startedAt.addingTimeInterval(10 * 3600)    // ativo 10h depois do start
        let at = { (h: Double) in lastActive.addingTimeInterval(h * 3600) }
        #expect(!node.isStale(now: at(1.9), threshold: 7200, lastActive: lastActive))
        #expect(node.isStale(now: at(2), threshold: 7200, lastActive: lastActive))
        #expect(node.idleSince(lastActive: lastActive) == lastActive)
        #expect(node.idleSince(lastActive: nil) == node.startedAt)
        // lastActive de um pid antigo (anterior ao start) não conta
        #expect(node.idleSince(lastActive: node.startedAt.addingTimeInterval(-60)) == node.startedAt)
    }
}
