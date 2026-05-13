import Foundation

public enum ProfileValidationError: Error, Equatable, LocalizedError, Sendable {
    case missingHost
    case invalidPort(Int)
    case noConnectionPort

    public var errorDescription: String? {
        switch self {
        case .missingHost:
            "Host is required."
        case .invalidPort(let port):
            "Port \(port) is outside the valid range 1-65535."
        case .noConnectionPort:
            "A SPICE port or TLS port is required."
        }
    }
}

public enum ProfileValidator {
    public static func validate(_ profile: ConnectionProfile) throws {
        if profile.host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ProfileValidationError.missingHost
        }

        if let port = profile.port {
            try validatePort(port)
        }

        if let tlsPort = profile.tlsPort {
            try validatePort(tlsPort)
        }

        if profile.port == nil && profile.tlsPort == nil {
            throw ProfileValidationError.noConnectionPort
        }
    }

    private static func validatePort(_ port: Int) throws {
        if port < 1 || port > 65_535 {
            throw ProfileValidationError.invalidPort(port)
        }
    }
}

