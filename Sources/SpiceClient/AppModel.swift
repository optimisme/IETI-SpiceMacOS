import AppKit
import SpiceCore
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedFileName: String?
    @Published var selectedConnection: ImportedConnection?
    @Published var statusMessage = "Select a .vv file."
    @Published var errorMessage: String?
    @Published var backendPath: String = UserDefaults.standard.string(forKey: "backendPath") ?? ""
    @Published var showDiagnostics: Bool = UserDefaults.standard.object(forKey: "showDiagnostics") as? Bool ?? true
    @Published var isLaunching = false

    private let launcher = BackendLauncher()
    private var activeProcesses: [Process] = []
    var canLaunch: Bool {
        selectedConnection != nil && !isLaunching
    }

    var isBackendAvailable: Bool {
        launcher.resolveBackendPath(configuration: backendConfiguration()) != nil
    }

    var backendInstallMessage: String {
        "Install SPICE GTK with Homebrew:\n\(BackendError.spiceGTKInstallCommand)"
    }

    func chooseVirtViewerFile() {
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "vv")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Choose SPICE .vv File"

        if panel.runModal() == .OK, let url = panel.url {
            openVirtViewerFile(at: url)
        }
    }

    func openVirtViewerFile(at url: URL) {
        do {
            let contents = try String(contentsOf: url, encoding: .utf8)
            let imported = try VirtViewerFileParser.parse(contents)
            selectedFileName = url.lastPathComponent
            selectedConnection = imported
            statusMessage = "Loaded \(url.lastPathComponent)."
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "Could not open \(url.lastPathComponent)."
        }
    }

    func launchSelectedConnection() {
        guard let selectedConnection else {
            chooseVirtViewerFile()
            return
        }

        launch(selectedConnection)
    }

    func terminateBackendProcesses() {
        activeProcesses.removeAll { process in
            if process.isRunning {
                process.terminate()
                return false
            }

            return true
        }
    }

    func backendStatus() -> String {
        if let path = launcher.resolveBackendPath(configuration: backendConfiguration()) {
            return "Backend found: \(path)"
        }

        return "SPICE GTK backend not found."
    }

    func backendDiagnostics() -> [BackendCandidate] {
        launcher.diagnostics(configuration: backendConfiguration())
    }

    func chooseBackendPath() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.title = "Choose SPICE Viewer Backend"

        if panel.runModal() == .OK, let url = panel.url {
            backendPath = url.path
            persistSettings()
        }
    }

    func persistSettings() {
        UserDefaults.standard.set(backendPath, forKey: "backendPath")
        UserDefaults.standard.set(showDiagnostics, forKey: "showDiagnostics")
    }

    private func launch(_ imported: ImportedConnection) {
        guard !isLaunching else {
            return
        }

        isLaunching = true
        do {
            let process = try launcher.launch(
                profile: imported.profile,
                password: imported.password,
                configuration: backendConfiguration(),
                outputHandler: { [weak self] line in
                    if line.contains("main channel: closed") {
                        Task { @MainActor in
                            self?.markRemoteDesktopClosed()
                        }
                    }
                },
                terminationHandler: { [weak self] terminatedProcess in
                    Task { @MainActor in
                        self?.activeProcesses.removeAll { $0.processIdentifier == terminatedProcess.processIdentifier }
                        self?.markRemoteDesktopClosed()
                    }
                }
            )
            activeProcesses.append(process)
            statusMessage = "Remote desktop launched."
            hideLauncherWindow()
        } catch {
            isLaunching = false
            errorMessage = Self.displayMessage(for: error)
            statusMessage = "Launch failed."
        }
    }

    private static func displayMessage(for error: Error) -> String {
        let localizedError = error as? LocalizedError
        let description = localizedError?.errorDescription ?? error.localizedDescription
        guard let recoverySuggestion = localizedError?.recoverySuggestion, !recoverySuggestion.isEmpty else {
            return description
        }

        return "\(description)\n\n\(recoverySuggestion)"
    }

    private func markRemoteDesktopClosed() {
        guard isLaunching else {
            return
        }

        isLaunching = false
        statusMessage = "Remote desktop closed."
        showLauncherWindow()
    }

    private func hideLauncherWindow() {
        NSApp.hide(nil)
    }

    private func showLauncherWindow() {
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.forEach { window in
            window.makeKeyAndOrderFront(nil)
        }
    }

    private func backendConfiguration() -> BackendConfiguration {
        return BackendConfiguration(
            customBackendPath: backendPath.isEmpty ? nil : backendPath
        )
    }
}
