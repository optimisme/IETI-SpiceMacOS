import Testing
@testable import SpiceCore

@Suite
struct CompatibilityFeatureTests {
    @Test
    func clipboardCompatibilityIsTracked() throws {
        let clipboard = try #require(
            CompatibilityMatrix.current.first { $0.name == "Clipboard Copy/Paste" }
        )

        #expect(clipboard.status == .delegated)
        #expect(clipboard.details.contains("SPICE server"))
        #expect(clipboard.details.contains("spice-vdagent"))
        #expect(clipboard.validationStatus.contains("Validated"))
    }
}
