// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Ports",
    platforms: [.macOS(.v26)],
    targets: [
        .target(name: "PortsCore"),
        .executableTarget(name: "Ports", dependencies: ["PortsCore"]),
        .testTarget(name: "PortsCoreTests", dependencies: ["PortsCore"]),
    ]
)
