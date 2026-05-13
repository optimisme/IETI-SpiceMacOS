import Foundation
import Testing
@testable import SpiceCore

@Suite
struct ProfileStoreTests {
    @Test
    func clearSecretReferencesKeepsProfiles() throws {
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("profiles-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let store = ProfileStore(fileURL: fileURL)
        let profile = ConnectionProfile(
            name: "Local",
            host: "127.0.0.1",
            port: 5900,
            passwordKeychainAccount: "secret-account"
        )

        try store.add(profile)
        try store.clearSecretReferences()

        #expect(store.profiles.count == 1)
        #expect(store.profiles[0].host == "127.0.0.1")
        #expect(store.profiles[0].passwordKeychainAccount == nil)
    }
}
