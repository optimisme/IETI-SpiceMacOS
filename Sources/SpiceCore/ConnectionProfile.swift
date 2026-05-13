import Foundation

public struct ConnectionProfile: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var host: String
    public var port: Int?
    public var tlsPort: Int?
    public var username: String?
    public var passwordKeychainAccount: String?
    public var tlsEnabled: Bool
    public var verifyCertificate: Bool
    public var caCertificatePath: String?
    public var caCertificatePEM: String?
    public var certificateSubject: String?
    public var proxyURL: String?
    public var secureChannels: String?
    public var releaseCursorShortcut: String?
    public var toggleFullscreenShortcut: String?
    public var lastConnectedAt: Date?

    public init(
        id: UUID = UUID(),
        name: String,
        host: String,
        port: Int? = 5900,
        tlsPort: Int? = nil,
        username: String? = nil,
        passwordKeychainAccount: String? = nil,
        tlsEnabled: Bool = false,
        verifyCertificate: Bool = true,
        caCertificatePath: String? = nil,
        caCertificatePEM: String? = nil,
        certificateSubject: String? = nil,
        proxyURL: String? = nil,
        secureChannels: String? = nil,
        releaseCursorShortcut: String? = nil,
        toggleFullscreenShortcut: String? = nil,
        lastConnectedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.tlsPort = tlsPort
        self.username = username
        self.passwordKeychainAccount = passwordKeychainAccount
        self.tlsEnabled = tlsEnabled
        self.verifyCertificate = verifyCertificate
        self.caCertificatePath = caCertificatePath
        self.caCertificatePEM = caCertificatePEM
        self.certificateSubject = certificateSubject
        self.proxyURL = proxyURL
        self.secureChannels = secureChannels
        self.releaseCursorShortcut = releaseCursorShortcut
        self.toggleFullscreenShortcut = toggleFullscreenShortcut
        self.lastConnectedAt = lastConnectedAt
    }
}

public struct ImportedConnection: Equatable, Sendable {
    public var profile: ConnectionProfile
    public var password: String?
    public var source: ImportSource

    public init(profile: ConnectionProfile, password: String? = nil, source: ImportSource) {
        self.profile = profile
        self.password = password
        self.source = source
    }
}

public enum ImportSource: String, Equatable, Sendable {
    case spiceURL
    case virtViewerFile
    case manual
}
