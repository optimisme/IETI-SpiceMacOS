import Testing
@testable import SpiceCore

@Suite
struct SpiceURLParserTests {
    @Test
    func parsesHostPortAndPassword() throws {
        let imported = try SpiceURLParser.parse("spice://vm.example.test:5901?password=secret")

        #expect(imported.profile.host == "vm.example.test")
        #expect(imported.profile.port == 5901)
        #expect(imported.password == "secret")
        #expect(imported.source == .spiceURL)
    }

    @Test
    func parsesTLSPortAndCertificateFlag() throws {
        let imported = try SpiceURLParser.parse("spice://vm.example.test?tls-port=5902&verify-certificate=false")

        #expect(imported.profile.tlsPort == 5902)
        #expect(imported.profile.tlsEnabled)
        #expect(!imported.profile.verifyCertificate)
    }

    @Test
    func rejectsUnsupportedScheme() {
        #expect(throws: SpiceURLParseError.unsupportedScheme("vnc")) {
            try SpiceURLParser.parse("vnc://vm.example.test:5901")
        }
    }

    @Test
    func rejectsInvalidQueryPort() {
        #expect(throws: SpiceURLParseError.invalidPort("abc")) {
            try SpiceURLParser.parse("spice://vm.example.test?port=abc")
        }
    }
}

