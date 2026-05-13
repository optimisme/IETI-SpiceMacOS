import Foundation

public enum SpiceURLParseError: Error, Equatable, LocalizedError, Sendable {
    case invalidURL
    case unsupportedScheme(String?)
    case missingHost
    case invalidPort(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The SPICE URL is invalid."
        case .unsupportedScheme(let scheme):
            "Unsupported URL scheme: \(scheme ?? "none")."
        case .missingHost:
            "The SPICE URL is missing a host."
        case .invalidPort(let value):
            "Invalid port value: \(value)."
        }
    }
}

public enum SpiceURLParser {
    public static func parse(_ rawValue: String) throws -> ImportedConnection {
        guard let components = URLComponents(string: rawValue) else {
            throw SpiceURLParseError.invalidURL
        }

        guard components.scheme?.lowercased() == "spice" else {
            throw SpiceURLParseError.unsupportedScheme(components.scheme)
        }

        guard let host = components.host, !host.isEmpty else {
            throw SpiceURLParseError.missingHost
        }

        let query = queryItems(from: components)
        let explicitPort = components.port
        let port = explicitPort ?? intValue(query["port"])
        let tlsPort = intValue(query["tls-port"] ?? query["tlsPort"] ?? query["sport"])
        let password = query["password"] ?? query["passwd"]
        let username = query["username"] ?? query["user"]
        let verifyCertificate = boolValue(query["verify-certificate"] ?? query["verifyCertificate"], defaultValue: true)
        let tlsEnabled = tlsPort != nil || boolValue(query["tls"], defaultValue: false)

        if let portValue = query["port"], intValue(portValue) == nil {
            throw SpiceURLParseError.invalidPort(portValue)
        }

        if let tlsPortValue = query["tls-port"] ?? query["tlsPort"] ?? query["sport"], intValue(tlsPortValue) == nil {
            throw SpiceURLParseError.invalidPort(tlsPortValue)
        }

        var profile = ConnectionProfile(
            name: defaultName(host: host, port: port, tlsPort: tlsPort),
            host: host,
            port: port,
            tlsPort: tlsPort,
            username: username,
            tlsEnabled: tlsEnabled,
            verifyCertificate: verifyCertificate
        )

        if let subject = query["host-subject"] ?? query["hostSubject"] {
            profile.certificateSubject = subject
        }

        try ProfileValidator.validate(profile)
        return ImportedConnection(profile: profile, password: password, source: .spiceURL)
    }

    private static func queryItems(from components: URLComponents) -> [String: String] {
        Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
            guard let value = item.value else { return nil }
            return (item.name, value)
        })
    }

    private static func intValue(_ value: String?) -> Int? {
        guard let value else { return nil }
        return Int(value)
    }

    private static func boolValue(_ value: String?, defaultValue: Bool) -> Bool {
        guard let value else { return defaultValue }
        switch value.lowercased() {
        case "1", "true", "yes", "on":
            return true
        case "0", "false", "no", "off":
            return false
        default:
            return defaultValue
        }
    }

    private static func defaultName(host: String, port: Int?, tlsPort: Int?) -> String {
        if let port {
            return "\(host):\(port)"
        }

        if let tlsPort {
            return "\(host):\(tlsPort)"
        }

        return host
    }
}

