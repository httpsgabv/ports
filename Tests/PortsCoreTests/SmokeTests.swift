import Testing
@testable import PortsCore

@Test func versionIsSet() {
    #expect(!PortsCore.version.isEmpty)
}
