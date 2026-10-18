import SwiftUI

@main
struct PortsApp: App {
    var body: some Scene {
        MenuBarExtra {
            RootView()
        } label: {
            Image(systemName: "point.3.connected.trianglepath.dotted")
        }
        .menuBarExtraStyle(.window)
    }
}
