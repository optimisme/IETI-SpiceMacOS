import Foundation

public enum BackendError: Error, Equatable, LocalizedError, Sendable {
    case backendNotFound
    case launchFailed(String)
    case tempFileFailed(String)

    public var errorDescription: String? {
        switch self {
        case .backendNotFound:
            "No SPICE viewer backend was found. Install it with: brew install spice-gtk"
        case .launchFailed(let message):
            "Could not launch SPICE viewer: \(message)"
        case .tempFileFailed(let message):
            "Could not create a temporary backend file: \(message)"
        }
    }
}

public struct BackendConfiguration: Equatable, Sendable {
    public var customBackendPath: String?
    public var additionalSearchPaths: [String]
    public var includeStandardSearchPaths: Bool

    public init(
        customBackendPath: String? = nil,
        additionalSearchPaths: [String] = [],
        includeStandardSearchPaths: Bool = true
    ) {
        self.customBackendPath = customBackendPath
        self.additionalSearchPaths = additionalSearchPaths
        self.includeStandardSearchPaths = includeStandardSearchPaths
    }
}

public struct BackendLaunchPlan: Equatable, Sendable {
    public var executablePath: String
    public var arguments: [String]
    public var environment: [String: String]
    public var sanitizedDescription: String
    public var connectionFileContents: String
    public var caCertificateContents: String?
    public var kind: BackendKind

    public init(
        executablePath: String,
        arguments: [String],
        environment: [String: String] = [:],
        sanitizedDescription: String,
        connectionFileContents: String = "",
        caCertificateContents: String? = nil,
        kind: BackendKind
    ) {
        self.executablePath = executablePath
        self.arguments = arguments
        self.environment = environment
        self.sanitizedDescription = sanitizedDescription
        self.connectionFileContents = connectionFileContents
        self.caCertificateContents = caCertificateContents
        self.kind = kind
    }
}

public struct BackendCandidate: Equatable, Sendable {
    public var path: String
    public var source: BackendCandidateSource
    public var kind: BackendKind
    public var exists: Bool
    public var isExecutable: Bool

    public init(path: String, source: BackendCandidateSource, kind: BackendKind, exists: Bool, isExecutable: Bool) {
        self.path = path
        self.source = source
        self.kind = kind
        self.exists = exists
        self.isExecutable = isExecutable
    }
}

public enum BackendKind: String, Equatable, Sendable {
    case spicy
    case remoteViewer
}

public enum BackendCandidateSource: String, Equatable, Sendable {
    case custom
    case bundled
    case additional
    case homebrew
    case system
}

public final class BackendLauncher {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func resolveBackendPath(configuration: BackendConfiguration) -> String? {
        diagnostics(configuration: configuration).first(where: \.isExecutable)?.path
    }

    public func diagnostics(configuration: BackendConfiguration) -> [BackendCandidate] {
        candidatePaths(configuration: configuration).map { candidate in
            var isDirectory: ObjCBool = false
            let exists = fileManager.fileExists(atPath: candidate.path, isDirectory: &isDirectory)
            return BackendCandidate(
                path: candidate.path,
                source: candidate.source,
                kind: candidate.kind,
                exists: exists && !isDirectory.boolValue,
                isExecutable: fileManager.isExecutableFile(atPath: candidate.path)
            )
        }
    }

    public func makeLaunchPlan(
        profile: ConnectionProfile,
        password: String?,
        configuration: BackendConfiguration
    ) throws -> BackendLaunchPlan {
        guard let backend = diagnostics(configuration: configuration).first(where: \.isExecutable) else {
            throw BackendError.backendNotFound
        }

        switch backend.kind {
        case .remoteViewer:
            return makeRemoteViewerLaunchPlan(backendPath: backend.path, profile: profile, password: password)
        case .spicy:
            return makeSpiceGTKLaunchPlan(
                backendPath: backend.path,
                profile: profile,
                password: password
            )
        }
    }

    private func makeRemoteViewerLaunchPlan(
        backendPath: String,
        profile: ConnectionProfile,
        password: String?
    ) -> BackendLaunchPlan {
        let connectionFile = Self.makeVirtViewerFile(profile: profile, password: password, redactPassword: false)
        let sanitizedFile = Self.makeVirtViewerFile(profile: profile, password: password, redactPassword: true)

        return BackendLaunchPlan(
            executablePath: backendPath,
            arguments: [],
            sanitizedDescription: "\(backendPath) <temporary .vv file>\n\(sanitizedFile)",
            connectionFileContents: connectionFile,
            kind: .remoteViewer
        )
    }

    private func makeSpiceGTKLaunchPlan(
        backendPath: String,
        profile: ConnectionProfile,
        password: String?
    ) -> BackendLaunchPlan {
        var arguments: [String] = ["--host=\(profile.host)"]

        if let tlsPort = profile.tlsPort {
            arguments.append("--secure-port=\(tlsPort)")
        } else if let port = profile.port {
            arguments.append("--port=\(port)")
        }

        if let password, !password.isEmpty {
            arguments.append("--password=\(password)")
        }

        if !profile.name.isEmpty {
            arguments.append("--title=\(profile.name)")
        }

        if let certificateSubject = profile.certificateSubject, !certificateSubject.isEmpty {
            arguments.append("--spice-host-subject=\(certificateSubject)")
        }

        if let secureChannels = profile.secureChannels, !secureChannels.isEmpty {
            let supportedChannels = Self.supportedSecureChannels(from: secureChannels)
            if !supportedChannels.isEmpty {
                arguments.append("--spice-secure-channels=\(supportedChannels)")
            }
        }

        arguments.append("--spice-disable-audio")
        arguments.append("--spice-disable-usbredir")

        if profile.caCertificatePEM?.isEmpty == false || profile.caCertificatePath?.isEmpty == false {
            arguments.append("--spice-ca-file=<temporary-ca-file>")
        }

        let sanitizedArguments = arguments.map { argument in
            argument.hasPrefix("--password=") ? "--password=<redacted>" : argument
        }
        var environment = Self.homebrewRuntimeEnvironment(for: backendPath)
        if let proxyURL = profile.proxyURL {
            environment["SPICE_PROXY"] = proxyURL
        }
        var sanitizedEnvironmentItems: [String] = []
        if environment["SPICE_PROXY"] != nil {
            sanitizedEnvironmentItems.append("SPICE_PROXY=<configured>")
        }
        if environment["DYLD_LIBRARY_PATH"] != nil {
            sanitizedEnvironmentItems.append("DYLD_LIBRARY_PATH=<homebrew-lib>")
        }
        if environment["GI_TYPELIB_PATH"] != nil {
            sanitizedEnvironmentItems.append("GI_TYPELIB_PATH=<homebrew-typelib>")
        }
        let sanitizedEnvironment = sanitizedEnvironmentItems.isEmpty ? "" : sanitizedEnvironmentItems.joined(separator: " ") + " "

        return BackendLaunchPlan(
            executablePath: backendPath,
            arguments: arguments,
            environment: environment,
            sanitizedDescription: "\(sanitizedEnvironment)\(backendPath) \(sanitizedArguments.joined(separator: " "))",
            caCertificateContents: profile.caCertificatePEM,
            kind: .spicy
        )
    }

    @discardableResult
    public func launch(
        profile: ConnectionProfile,
        password: String?,
        configuration: BackendConfiguration,
        outputHandler: (@Sendable (String) -> Void)? = nil,
        terminationHandler: (@Sendable (Process) -> Void)? = nil
    ) throws -> Process {
        let plan = try makeLaunchPlan(profile: profile, password: password, configuration: configuration)
        var cleanupURLs: [URL] = []
        let process = Process()
        process.executableURL = URL(fileURLWithPath: plan.executablePath)
        process.environment = ProcessInfo.processInfo.environment.merging(plan.environment) { _, new in new }
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        if outputHandler != nil {
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            outputPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else {
                    return
                }

                outputHandler?(text)
            }
            errorPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else {
                    return
                }

                outputHandler?(text)
            }
        }

        switch plan.kind {
        case .remoteViewer:
            let tempURL = try writeTemporaryFile(contents: plan.connectionFileContents, extension: "vv")
            cleanupURLs.append(tempURL)
            process.arguments = [tempURL.path]
        case .spicy:
            var arguments = plan.arguments
            if let caCertificateContents = plan.caCertificateContents {
                let caURL = try writeTemporaryFile(contents: caCertificateContents, extension: "crt")
                cleanupURLs.append(caURL)
                arguments = arguments.map { argument in
                    argument == "--spice-ca-file=<temporary-ca-file>" ? "--spice-ca-file=\(caURL.path)" : argument
                }
            } else if let caCertificatePath = profile.caCertificatePath {
                arguments = arguments.map { argument in
                    argument == "--spice-ca-file=<temporary-ca-file>" ? "--spice-ca-file=\(caCertificatePath)" : argument
                }
            }
            process.arguments = arguments
        }

        let cleanupURLsForTermination = cleanupURLs
        process.terminationHandler = { terminatedProcess in
            outputPipe.fileHandleForReading.readabilityHandler = nil
            errorPipe.fileHandleForReading.readabilityHandler = nil
            cleanupURLsForTermination.forEach { url in
                try? FileManager.default.removeItem(at: url)
            }
            terminationHandler?(terminatedProcess)
        }

        do {
            try process.run()
            return process
        } catch {
            cleanupURLs.forEach { url in
                try? fileManager.removeItem(at: url)
            }
            throw BackendError.launchFailed(error.localizedDescription)
        }
    }

    public static func makeVirtViewerFile(
        profile: ConnectionProfile,
        password: String?,
        redactPassword: Bool
    ) -> String {
        var lines = [
            "[virt-viewer]",
            "type=spice",
            "host=\(profile.host)"
        ]

        if let port = profile.port {
            lines.append("port=\(port)")
        }

        if let tlsPort = profile.tlsPort {
            lines.append("tls-port=\(tlsPort)")
        }

        if let username = profile.username, !username.isEmpty {
            lines.append("username=\(username)")
        }

        if let password, !password.isEmpty {
            lines.append("password=\(redactPassword ? "<redacted>" : password)")
        }

        if let caCertificatePath = profile.caCertificatePath, !caCertificatePath.isEmpty {
            lines.append("ca=\(caCertificatePath)")
        }

        if let caCertificatePEM = profile.caCertificatePEM, !caCertificatePEM.isEmpty {
            lines.append("ca=\(caCertificatePEM.replacingOccurrences(of: "\n", with: "\\n"))")
        }

        if let certificateSubject = profile.certificateSubject, !certificateSubject.isEmpty {
            lines.append("host-subject=\(certificateSubject)")
        }

        if let proxyURL = profile.proxyURL, !proxyURL.isEmpty {
            lines.append("proxy=\(proxyURL)")
        }

        if let secureChannels = profile.secureChannels, !secureChannels.isEmpty {
            lines.append("secure-channels=\(secureChannels)")
        }

        if let releaseCursorShortcut = profile.releaseCursorShortcut, !releaseCursorShortcut.isEmpty {
            lines.append("release-cursor=\(releaseCursorShortcut)")
        }

        if let toggleFullscreenShortcut = profile.toggleFullscreenShortcut, !toggleFullscreenShortcut.isEmpty {
            lines.append("toggle-fullscreen=\(toggleFullscreenShortcut)")
        }

        lines.append("delete-this-file=1")
        return lines.joined(separator: "\n") + "\n"
    }

    private func candidatePaths(configuration: BackendConfiguration) -> [(path: String, source: BackendCandidateSource, kind: BackendKind)] {
        var paths: [(path: String, source: BackendCandidateSource, kind: BackendKind)] = []

        if let customBackendPath = configuration.customBackendPath, !customBackendPath.isEmpty {
            paths.append((customBackendPath, .custom, Self.kind(for: customBackendPath)))
        }

        paths.append(contentsOf: configuration.additionalSearchPaths.map { ($0, .additional, Self.kind(for: $0)) })
        if configuration.includeStandardSearchPaths {
            paths.append(("/opt/homebrew/bin/spicy", .homebrew, .spicy))
            paths.append(("/usr/local/bin/spicy", .homebrew, .spicy))
            paths.append(("/opt/homebrew/bin/remote-viewer", .homebrew, .remoteViewer))
            paths.append(("/usr/local/bin/remote-viewer", .homebrew, .remoteViewer))
            paths.append(("/Applications/Remote Viewer.app/Contents/MacOS/remote-viewer", .system, .remoteViewer))
            paths.append(("/usr/bin/remote-viewer", .system, .remoteViewer))
        }

        var seen = Set<String>()
        return paths.filter { candidate in
            if seen.contains(candidate.path) {
                return false
            }

            seen.insert(candidate.path)
            return true
        }
    }

    private static func kind(for path: String) -> BackendKind {
        URL(fileURLWithPath: path).lastPathComponent == "spicy" ? .spicy : .remoteViewer
    }

    private static func homebrewRuntimeEnvironment(for backendPath: String) -> [String: String] {
        guard backendPath.hasPrefix("/opt/homebrew/") || backendPath.hasPrefix("/usr/local/") else {
            return [:]
        }

        let prefix = backendPath.hasPrefix("/opt/homebrew/") ? "/opt/homebrew" : "/usr/local"
        return [
            "DYLD_LIBRARY_PATH": "\(prefix)/lib",
            "GI_TYPELIB_PATH": "\(prefix)/lib/girepository-1.0"
        ]
    }

    private static func supportedSecureChannels(from rawValue: String) -> String {
        rawValue
            .replacingOccurrences(of: ";", with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { channel in
                !["playback", "record", "usbredir", "smartcard"].contains(channel)
            }
            .joined(separator: ",")
    }

    private func writeTemporaryFile(contents: String, extension fileExtension: String) throws -> URL {
        let directory = fileManager.temporaryDirectory.appendingPathComponent("SpiceClient", isDirectory: true)

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let fileURL = directory.appendingPathComponent("\(UUID().uuidString).\(fileExtension)")
            guard let data = contents.data(using: .utf8) else {
                throw BackendError.tempFileFailed("Connection file is not valid UTF-8.")
            }

            fileManager.createFile(
                atPath: fileURL.path,
                contents: data,
                attributes: [.posixPermissions: 0o600]
            )
            return fileURL
        } catch let backendError as BackendError {
            throw backendError
        } catch {
            throw BackendError.tempFileFailed(error.localizedDescription)
        }
    }
}
