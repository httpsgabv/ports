import Foundation
import Testing
@testable import PortsCore

@Suite struct ParserTests {
    @Test func lsofListenGroupsAndDedupesPorts() {
        let r = parseLsofListen(Fixture.lsofListen)
        #expect(r.count == 5)
        #expect(r[627]?.name == "ControlCenter")
        #expect(r[627]?.ports == [5000, 7000])     // v4+v6 deduped
        #expect(r[620]?.ports == [58996])
        #expect(r[47102]?.ports == [5174])         // [::1]:5174
        #expect(r[41643]?.ports == [7265])
    }

    @Test func connectionsNeverBecomePorts() {
        let r = parseLsofListen(Fixture.lsofTCP)
        #expect(r[7359]?.ports == [8781])          // não 64384/64390
        #expect(r[620]?.ports == [58996])          // não 58465
        #expect(r[900]?.ports == [3000])           // não 5432/60001
    }

    @Test func countsOnlyInboundConnections() {
        let r = parseLsofListen(Fixture.lsofTCP)
        #expect(r[7359]?.inbound == [8781, 8781])  // 2 clientes
        #expect(r[620]?.inbound == [58996])
        #expect(r[900]?.inbound == [])             // só saída (node → postgres)
    }

    @Test func dropsPidsWithoutListen() {
        let r = parseLsofListen(Fixture.lsofTCP)
        #expect(r[7373] == nil)                    // nc: só conexão de saída
        #expect(r[671] == nil)
        #expect(r.count == 3)
    }

    @Test func lsofListenEmpty() {
        #expect(parseLsofListen("").isEmpty)
    }

    @Test func psDetailsParsesDateCpuRssAndPathWithSpaces() throws {
        let r = parsePsDetails(Fixture.psDetails)
        #expect(r.count == 5)

        let node = try #require(r[47102])
        #expect(node.cpu == 1.5)
        #expect(node.rssBytes == 16496 * 1024)
        #expect(node.executablePath == "node")
        let c = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: node.startedAt)
        #expect([c.year, c.month, c.day, c.hour, c.minute, c.second] == [2026, 10, 17, 21, 15, 53])

        let figma = try #require(r[97731])   // "Oct  1" double space + path with space
        #expect(figma.executablePath == "/Users/gabriel/Library/Application Support/Figma/FigmaAgent.app/Contents/MacOS/figma_agent")
        #expect(Calendar.current.component(.day, from: figma.startedAt) == 1)
    }

    @Test func psCommandKeepsFullCommandLine() {
        let r = parsePsCommand(Fixture.psCommand)
        #expect(r[41643] == "/Applications/Raycast.app/Contents/MacOS/Raycast UPDATED_VERSION AUTOMATIC_UPDATE")
        #expect(r[47102]?.hasSuffix("--port 5174 --strictPort") == true)
    }

    @Test func lsofCwdDropsRoot() {
        let r = parseLsofCwd(Fixture.lsofCwd)
        #expect(r == [47102: "/Users/gabriel/Documents/dev/yt-city"])
    }

    @Test(arguments: [
        ("/usr/libexec/rapportd", true),
        ("/System/Library/CoreServices/ControlCenter.app/Contents/MacOS/ControlCenter", true),
        ("/Applications/Raycast.app/Contents/MacOS/Raycast", true),
        ("/Users/gabriel/Library/Application Support/Figma/FigmaAgent.app/Contents/MacOS/figma_agent", true),
        ("/usr/sbin/sshd", true),
        ("node", false),
        ("python3", false),
        ("/usr/bin/python3", false),
        ("/opt/homebrew/opt/postgresql@16/bin/postgres", false),
        ("/Library/Frameworks/Python.framework/Versions/3.14/Resources/Python.app/Contents/MacOS/Python", false),
        ("/opt/homebrew/Cellar/python@3.13/3.13.1/Frameworks/Python.framework/Versions/3.13/Resources/Python.app/Contents/MacOS/Python", false),
        ("/Users/gabriel/dev/app/node_modules/electron/dist/Electron.app/Contents/MacOS/Electron", false),
    ])
    func systemPathClassification(path: String, expected: Bool) {
        #expect(isSystemPath(path) == expected)
    }

    @Test func mergeDropsVanishedPidsAndSortsByLowestPort() {
        let r = merge(
            listen: parseLsofListen(Fixture.lsofListen),
            details: parsePsDetails(Fixture.psDetails).filter { $0.key != 41643 },  // Raycast died mid-scan
            commands: parsePsCommand(Fixture.psCommand),
            cwds: parseLsofCwd(Fixture.lsofCwd)
        )
        #expect(r.map(\.pid) == [627, 47102, 97731, 620])
        let node = r[1]
        #expect(node.name == "node")
        #expect(node.cwd == "/Users/gabriel/Documents/dev/yt-city")
        #expect(node.isSystem == false)
        #expect(node.memoryBytes == 16496 * 1024)
        #expect(r[0].isSystem)
    }
}
