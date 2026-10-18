import Testing
@testable import PortsCore

@Suite struct FormattingTests {
    static let uptimes: [(Double, String)] = [
        (0, "0s"),
        (59.9, "59s"),
        (60, "1m"),
        (3540, "59m"),
        (11100, "3h 05m"),
        (86340, "23h 59m"),
        (86400, "1d 0h"),
        (189000, "2d 4h"),        // 2d 4h 30m: trunca minutos
        (-5, "0s"),               // relógio ajustado
    ]

    @Test(arguments: uptimes)
    func uptime(seconds: Double, expected: String) {
        #expect(formatUptime(seconds) == expected)
    }

    static let MB: UInt64 = 1 << 20
    static let sizes: [(UInt64, String)] = [
        (0, "0 KB"),
        (512 << 10, "512 KB"),
        (16 * MB, "16 MB"),
        (1023 * MB, "1023 MB"),
        (1024 * MB, "1.0 GB"),
        (1280 * MB, "1.2 GB"),   // 1.25 GB: %.1f arredonda p/ 1.2 (half-even em binário)
    ]

    @Test(arguments: sizes)
    func bytes(value: UInt64, expected: String) {
        #expect(formatBytes(value) == expected)
    }

    @Test func cpu() {
        #expect(formatCPU(0) == "0.0%")
        #expect(formatCPU(4.06) == "4.1%")
        #expect(formatCPU(250) == "250%")
    }

    @Test(arguments: [
        ("/Users/gabriel/dev/app", "~/dev/app"),
        ("/Users/gabriel", "~"),
        ("/Users/gabrielle/x", "/Users/gabrielle/x"),   // prefixo sem "/" não abrevia
        ("/private/tmp/x", "/private/tmp/x"),
    ])
    func home(path: String, expected: String) {
        #expect(abbreviateHome(path, home: "/Users/gabriel") == expected)
    }
}
