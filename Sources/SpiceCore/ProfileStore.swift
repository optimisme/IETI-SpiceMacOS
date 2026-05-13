import Foundation

public final class ProfileStore: ObservableObject {
    @Published public private(set) var profiles: [ConnectionProfile]

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(fileURL: URL? = nil) {
        let defaultURL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("SpiceClient", isDirectory: true)
            .appendingPathComponent("profiles.json")

        self.fileURL = fileURL ?? defaultURL
        self.profiles = []
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
        load()
    }

    public func add(_ profile: ConnectionProfile) throws {
        var next = profiles
        next.append(profile)
        try save(next)
    }

    public func update(_ profile: ConnectionProfile) throws {
        var next = profiles

        if let index = next.firstIndex(where: { $0.id == profile.id }) {
            next[index] = profile
        } else {
            next.append(profile)
        }

        try save(next)
    }

    public func delete(_ profile: ConnectionProfile) throws {
        try save(profiles.filter { $0.id != profile.id })
    }

    public func markConnected(_ profile: ConnectionProfile, at date: Date = Date()) throws {
        var next = profile
        next.lastConnectedAt = date
        try update(next)
    }

    public func clearSecretReferences() throws {
        let next = profiles.map { profile in
            var updated = profile
            updated.passwordKeychainAccount = nil
            return updated
        }

        try save(next)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else {
            profiles = []
            return
        }

        profiles = (try? decoder.decode([ConnectionProfile].self, from: data)) ?? []
    }

    private func save(_ nextProfiles: [ConnectionProfile]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let data = try encoder.encode(nextProfiles)
        try data.write(to: fileURL, options: [.atomic])
        profiles = nextProfiles
    }
}
