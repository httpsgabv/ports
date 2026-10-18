import SwiftUI

@main
struct PortsApp: App {
    @State private var store = PortStore()

    var body: some Scene {
        MenuBarExtra {
            RootView()
                .environment(store)
        } label: {
            MenuBarLabel(count: store.processes.count, stale: store.hasStale)
        }
        .menuBarExtraStyle(.window)
    }
}
