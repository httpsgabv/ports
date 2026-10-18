import Foundation
import Observation
import PortsCore

@Observable @MainActor
final class PortStore {
    private(set) var all: [ListeningProcess] = []
    private(set) var lastError: String?
    private(set) var lastScan: Date?
    var showSystem = false
    var staleThreshold: TimeInterval = 2 * 3600
    /// Aberto: scan completo (cpu/mem ao vivo). Fechado: só portas + pids novos (contador barato).
    var isPopoverOpen = false

    private var isScanning = false

    var processes: [ListeningProcess] { visible(all, showSystem: showSystem) }
    var hasStale: Bool { processes.contains(where: isStale) }

    init() {
        Task { [weak self] in
            while let self {
                await self.refresh()
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }

    func refresh() async {
        guard !isScanning else { return }
        isScanning = true
        defer { isScanning = false }
        do {
            all = try await scan(reusing: isPopoverOpen ? [] : all)   // nonisolated: fora da main thread
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        lastScan = .now
    }

    func isStale(_ process: ListeningProcess) -> Bool {
        process.isStale(threshold: staleThreshold)
    }

    func remove(_ pid: Int32) {
        all.removeAll { $0.pid == pid }
    }
}
