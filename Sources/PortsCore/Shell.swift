import Foundation

public struct ShellError: LocalizedError, Sendable {
    public let errorDescription: String?
}

/// Roda um binário e devolve o stdout. `okStatuses`: lsof/ps saem com 1 quando algum pid/resultado falta.
/// `timeout`: mata o processo se passar do limite (docker com daemon travado).
func run(_ path: String, _ args: [String], okStatuses: Set<Int32> = [0, 1], timeout: Duration? = nil) async throws -> String {
    // ponytail: bloqueia uma thread do pool por ~50ms; trocar por terminationHandler se virar gargalo
    try await Task.detached {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        // HOME: o docker acha o contexto em ~/.docker; PATH: credential helpers do docker
        process.environment = ["LC_ALL": "C", "HOME": NSHomeDirectory(), "PATH": "/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/homebrew/bin"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            throw ShellError(errorDescription: "\(path): \(error.localizedDescription)")
        }
        let watchdog = DispatchWorkItem { if process.isRunning { process.terminate() } }
        if let timeout {
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout / .seconds(1), execute: watchdog)
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        watchdog.cancel()
        if process.terminationReason == .uncaughtSignal, timeout != nil {
            throw ShellError(errorDescription: "\((path as NSString).lastPathComponent) timed out")
        }
        guard okStatuses.contains(process.terminationStatus) else {
            throw ShellError(errorDescription: "\((path as NSString).lastPathComponent) exited \(process.terminationStatus)")
        }
        return String(decoding: data, as: UTF8.self)
    }.value
}
