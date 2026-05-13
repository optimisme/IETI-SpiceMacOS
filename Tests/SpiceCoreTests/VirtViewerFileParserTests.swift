import Foundation
import Testing
@testable import SpiceCore

@Suite
struct VirtViewerFileParserTests {
    @Test
    func parsesMinimalFile() throws {
        let imported = try VirtViewerFileParser.parse("""
        [virt-viewer]
        type=spice
        host=127.0.0.1
        port=5900
        """)

        #expect(imported.profile.host == "127.0.0.1")
        #expect(imported.profile.port == 5900)
        #expect(imported.profile.name == "127.0.0.1:5900")
        #expect(imported.source == .virtViewerFile)
    }

    @Test
    func parsesProxmoxStyleFile() throws {
        let imported = try VirtViewerFileParser.parse("""
        [virt-viewer]
        type=spice
        title=vm-101
        host=pve.example.test
        tls-port=61000
        password=temporary-ticket
        host-subject=O=cluster,CN=pve.example.test
        """)

        #expect(imported.profile.name == "vm-101")
        #expect(imported.profile.host == "pve.example.test")
        #expect(imported.profile.tlsPort == 61000)
        #expect(imported.profile.tlsEnabled)
        #expect(imported.profile.certificateSubject == "O=cluster,CN=pve.example.test")
        #expect(imported.password == "temporary-ticket")
    }

    @Test
    func rejectsUnsupportedType() {
        #expect(throws: VirtViewerParseError.unsupportedType("vnc")) {
            try VirtViewerFileParser.parse("""
            [virt-viewer]
            type=vnc
            host=127.0.0.1
            """)
        }
    }

    @Test
    func rejectsInvalidPort() {
        #expect(throws: VirtViewerParseError.invalidPort("bad")) {
            try VirtViewerFileParser.parse("""
            [virt-viewer]
            type=spice
            host=127.0.0.1
            port=bad
            """)
        }
    }

    @Test
    func parsesIsardFixture() throws {
        let fixtureURL = try #require(
            Bundle.module.url(forResource: "Fixtures/isard-spice", withExtension: "vv")
        )
        let contents = try String(contentsOf: fixtureURL, encoding: .utf8)
        let imported = try VirtViewerFileParser.parse(contents)

        #expect(imported.profile.name == "Debian AI (TLS):%d - Prem SHIFT+F12 per sortir")
        #expect(imported.profile.host == "isard-hypervisor")
        #expect(imported.profile.tlsPort == 5922)
        #expect(imported.profile.proxyURL == "http://gpu-a10-1.pilotfp.gencat.isardvdi.com:4104")
        #expect(imported.profile.certificateSubject == "CN=*.localdomain")
        #expect(imported.profile.caCertificatePEM?.contains("BEGIN CERTIFICATE") == true)
        #expect(imported.profile.secureChannels?.contains("display") == true)
        #expect(imported.profile.releaseCursorShortcut == "shift+f12")
        #expect(imported.password == "<redacted-test-password>")
    }
}
