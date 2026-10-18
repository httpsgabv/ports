import Foundation

public struct ShellError: LocalizedError, Sendable {
    public let errorDescription: String?
}

/// Roda um binário e devolve o stdout. `okStatuses`: lsof/ps saem com 1 quando algum pid/resultado falta.
func run(_ path: String, _ args: [String], okStatuses: Set<Int32> = [0, 1]) async throws -> String {
    // ponytail: bloqueia uma thread do pool por ~50ms; trocar por terminationHandler se virar gargalo
    try await Task.detached {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        process.environment = ["LC_ALL": "C"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            throw ShellError(errorDescription: "\(path): \(error.localizedDescription)")
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard okStatuses.contains(process.terminationStatus) else {
            throw ShellError(errorDescription: "\((path as NSString).lastPathComponent) exited \(process.terminationStatus)")
        }
        return String(decoding: data, as: UTF8.self)
    }.value
}
