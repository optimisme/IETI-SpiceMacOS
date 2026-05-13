import Foundation
import Testing
@testable import SpiceCore

@Suite
struct BackendLauncherTests {
    @Test
    func generatedVirtViewerFileCanRedactPassword() {
        let profile = ConnectionProfile(name: "Local", host: "127.0.0.1", port: 5900)

        let redacted = BackendLauncher.makeVirtViewerFile(
            profile: profile,
            password: "secret",
            redactPassword: true
        )

        #expect(redacted.contains("password=<redacted>"))
        #expect(!redacted.contains("password=secret"))
    }

    @Test
    func launchPlanDoesNotExposePasswordInDescription() throws {
        let executable = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("remote-viewer-test-\(UUID().uuidString)")
        FileManager.default.createFile(atPath: executable.path, contents: Data(), attributes: [.posixPermissions: 0o755])
        defer { try? FileManager.default.removeItem(at: executable) }

        let launcher = BackendLauncher()
        let profile = ConnectionProfile(name: "Local", host: "127.0.0.1", port: 5900)
        let plan = try launcher.makeLaunchPlan(
            profile: profile,
            password: "secret",
            configuration: BackendConfiguration(customBackendPath: executable.path)
        )

        #expect(plan.connectionFileContents.contains("password=secret"))
        #expect(plan.sanitizedDescription.contains("password=<redacted>"))
        #expect(!plan.sanitizedDescription.contains("secret"))
    }

    @Test
    func missingBackendThrows() {
        let launcher = BackendLauncher()
        let profile = ConnectionProfile(name: "Local", host: "127.0.0.1", port: 5900)

        #expect(throws: BackendError.backendNotFound) {
            try launcher.makeLaunchPlan(
                profile: profile,
                password: nil,
                configuration: BackendConfiguration(
                    customBackendPath: "/does/not/exist",
                    includeStandardSearchPaths: false
                )
            )
        }
    }

    @Test
    func diagnosticsReportCandidateStatus() throws {
        let executable = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("remote-viewer-diagnostics-\(UUID().uuidString)")
        FileManager.default.createFile(atPath: executable.path, contents: Data(), attributes: [.posixPermissions: 0o755])
        defer { try? FileManager.default.removeItem(at: executable) }

        let launcher = BackendLauncher()
        let diagnostics = launcher.diagnostics(
            configuration: BackendConfiguration(customBackendPath: executable.path)
        )

        let custom = try #require(diagnostics.first)
        #expect(custom.path == executable.path)
        #expect(custom.source == .custom)
        #expect(custom.exists)
        #expect(custom.isExecutable)
    }

    @Test
    func spicyLaunchPlanTranslatesProfileFields() throws {
        let executable = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("spicy")
        FileManager.default.createFile(atPath: executable.path, contents: Data(), attributes: [.posixPermissions: 0o755])
        defer { try? FileManager.default.removeItem(at: executable) }

        let launcher = BackendLauncher()
        let profile = ConnectionProfile(
            name: "Isard",
            host: "isard-hypervisor",
            port: nil,
            tlsPort: 5919,
            tlsEnabled: true,
            caCertificatePEM: "-----BEGIN CERTIFICATE-----\nexample\n-----END CERTIFICATE-----\n",
            certificateSubject: "CN=*.localdomain",
            proxyURL: "http://proxy.example.test:4104",
            secureChannels: "main;inputs;playback;record;display;usbredir;smartcard"
        )

        let plan = try launcher.makeLaunchPlan(
            profile: profile,
            password: "secret",
            configuration: BackendConfiguration(
                customBackendPath: executable.path,
                includeStandardSearchPaths: false
            )
        )

        #expect(plan.kind == .spicy)
        #expect(plan.arguments.contains("--host=isard-hypervisor"))
        #expect(plan.arguments.contains("--secure-port=5919"))
        #expect(plan.arguments.contains("--password=secret"))
        #expect(plan.arguments.contains("--spice-host-subject=CN=*.localdomain"))
        #expect(plan.arguments.contains("--spice-secure-channels=main,inputs,display"))
        #expect(plan.arguments.contains("--spice-disable-audio"))
        #expect(plan.arguments.contains("--spice-disable-usbredir"))
        #expect(plan.arguments.contains("--spice-ca-file=<temporary-ca-file>"))
        #expect(plan.environment["SPICE_PROXY"] == "http://proxy.example.test:4104")
        #expect(plan.environment["DYLD_LIBRARY_PATH"] == nil)
        #expect(plan.sanitizedDescription.contains("--password=<redacted>"))
        #expect(!plan.sanitizedDescription.contains("secret"))
    }

    @Test
    func homebrewSpicyLaunchPlanAddsRuntimeEnvironment() throws {
        let launcher = BackendLauncher()
        let profile = ConnectionProfile(name: "Local", host: "127.0.0.1", port: 5900)
        let plan = try launcher.makeLaunchPlan(
            profile: profile,
            password: nil,
            configuration: BackendConfiguration(customBackendPath: "/opt/homebrew/bin/spicy")
        )

        #expect(plan.kind == .spicy)
        #expect(plan.environment["DYLD_LIBRARY_PATH"] == "/opt/homebrew/lib")
        #expect(plan.environment["GI_TYPELIB_PATH"] == "/opt/homebrew/lib/girepository-1.0")
    }

    @Test
    func standardSearchPrefersHomebrewSpicy() throws {
        let launcher = BackendLauncher()
        let profile = ConnectionProfile(name: "Local", host: "127.0.0.1", port: 5900)
        let plan = try launcher.makeLaunchPlan(
            profile: profile,
            password: nil,
            configuration: BackendConfiguration()
        )

        #expect(plan.kind == .spicy)
        #expect(plan.executablePath.hasSuffix("/spicy"))
    }
}
