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
}
