import SpiceCore
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

@main
struct SpiceClientApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    model.terminateBackendProcesses()
                }
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Import .vv File...") {
                    model.chooseVirtViewerFile()
                }
                .keyboardShortcut("i", modifiers: [.command])
            }
        }

        Settings {
            SettingsView()
                .environmentObject(model)
        }
    }
}
