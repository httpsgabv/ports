import Foundation
import Observation
import PortsCore

@Observable @MainActor
final class PortStore {
    private(set) var all: [ListeningProcess] = []
    private(set) var lastError: String?
    private(set) var lastScan: Date?
    var showSystem = UserDefaults.standard.bool(forKey: "showSystem") {
        didSet { UserDefaults.standard.set(showSystem, forKey: "showSystem") }
    }
    var staleHours = UserDefaults.standard.object(forKey: "staleHours") as? Int ?? 2 {
        didSet { UserDefaults.standard.set(staleHours, forKey: "staleHours") }
    }
    var staleThreshold: TimeInterval { TimeInterval(staleHours) * 3600 }
    private(set) var expectedKeys = Set(UserDefaults.standard.stringArray(forKey: "expectedKeys") ?? []) {
        didSet { UserDefaults.standard.set(expectedKeys.sorted(), forKey: "expectedKeys") }
    }
    /// Aberto: scan completo (cpu/mem ao vivo). Fechado: só portas + pids novos (contador barato).
    var isPopoverOpen = false

    private var isScanning = false
    /// Última vez com conexão de entrada, por id. Só em memória (spec 09).
    private var lastActive: [String: Date] = [:]

    private var partition: (active: [ListeningProcess], expected: [ListeningProcess]) {
        split(visible(all, showSystem: showSystem), expected: expectedKeys)
    }
    /// Visíveis e não esperados: o que conta no ícone e pode ficar âmbar.
    var processes: [ListeningProcess] { partition.active }
    var expectedProcesses: [ListeningProcess] { partition.expected }
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
            let now = Date.now
            lastActive = lastActive.filter { id, _ in all.contains { $0.id == id } }
            for p in all where p.inboundConnections > 0 { lastActive[p.id] = now }
        } catch {
            lastError = error.localizedDescription
        }
        lastScan = .now
    }

    func isStale(_ process: ListeningProcess) -> Bool {
        process.isStale(threshold: staleThreshold, lastActive: lastActive[process.id])
    }

    func idleSince(_ process: ListeningProcess) -> Date {
        process.idleSince(lastActive: lastActive[process.id])
    }

    func isExpected(_ process: ListeningProcess) -> Bool {
        expectedKeys.contains(expectationKey(process))
    }

    func setExpected(_ processes: [ListeningProcess], _ expected: Bool) {
        let keys = processes.map(expectationKey)
        if expected { expectedKeys.formUnion(keys) } else { expectedKeys.subtract(keys) }
    }

    func remove(_ id: String) {
        all.removeAll { $0.id == id }
    }
}
