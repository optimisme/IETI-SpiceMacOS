import Testing
@testable import SpiceCore

@Suite
struct OpenSourceNoticeTests {
    @Test
    func noticesIncludeBackendDistributionWarning() throws {
        let spiceGTK = try #require(OpenSourceNotices.current.first { $0.name.contains("spicy") })

        #expect(spiceGTK.license.contains("GPL"))
        #expect(spiceGTK.license.contains("LGPL"))
        #expect(spiceGTK.distributionNotes.contains("Homebrew"))
        #expect(spiceGTK.sourceURL.absoluteString.contains("spice-gtk"))
    }

    @Test
    func noticesIncludeNativeIntegrationWarning() throws {
        let spiceClientGLib = try #require(OpenSourceNotices.current.first { $0.name.contains("spice-client-glib") })

        #expect(spiceClientGLib.license.contains("Verify"))
        #expect(spiceClientGLib.distributionNotes.contains("dynamic linking"))
    }
}
