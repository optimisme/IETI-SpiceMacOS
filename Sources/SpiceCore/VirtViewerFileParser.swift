import Foundation

public enum VirtViewerParseError: Error, Equatable, LocalizedError, Sendable {
    case missingVirtViewerSection
    case unsupportedType(String?)
    case missingHost
    case invalidPort(String)

    public var errorDescription: String? {
        switch self {
        case .missingVirtViewerSection:
            "The file does not contain a [virt-viewer] section."
        case .unsupportedType(let type):
            "Unsupported virt-viewer connection type: \(type ?? "none")."
        case .missingHost:
            "The virt-viewer file is missing a host."
        case .invalidPort(let value):
            "Invalid port value: \(value)."
        }
    }
}

public enum VirtViewerFileParser {
    public static func parse(_ contents: String) throws -> ImportedConnection {
        let values = parseKeyValueSections(contents)
        guard let section = values["virt-viewer"] else {
            throw VirtViewerParseError.missingVirtViewerSection
        }

        let type = section["type"]?.lowercased()
        guard type == nil || type == "spice" else {
            throw VirtViewerParseError.unsupportedType(type)
        }

        guard let host = section["host"], !host.isEmpty else {
            throw VirtViewerParseError.missingHost
        }

        let port = try parsePort(section["port"])
        let tlsPort = try parsePort(section["tls-port"] ?? section["sport"])
        let password = section["password"] ?? section["passwd"]
        let title = section["title"] ?? section["name"] ?? defaultName(host: host, port: port, tlsPort: tlsPort)
        let verifyCertificate = boolValue(section["verify-certificate"] ?? section["verify"], defaultValue: true)

        var profile = ConnectionProfile(
            name: title,
            host: host,
            port: port,
            tlsPort: tlsPort,
            username: section["username"] ?? section["user"],
            tlsEnabled: tlsPort != nil,
            verifyCertificate: verifyCertificate,
            caCertificatePath: caCertificatePath(from: section["ca"]),
            caCertificatePEM: caCertificatePEM(from: section["ca"]),
            certificateSubject: section["host-subject"],
            proxyURL: section["proxy"],
            secureChannels: section["secure-channels"],
            releaseCursorShortcut: section["release-cursor"],
            toggleFullscreenShortcut: section["toggle-fullscreen"]
        )

        if profile.port == nil && profile.tlsPort == nil {
            profile.port = 5900
        }

        try ProfileValidator.validate(profile)
        return ImportedConnection(profile: profile, password: password, source: .virtViewerFile)
    }

    private static func parseKeyValueSections(_ contents: String) -> [String: [String: String]] {
        var sections: [String: [String: String]] = [:]
        var currentSection: String?

        for rawLine in contents.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)

            if line.isEmpty || line.hasPrefix("#") || line.hasPrefix(";") {
                continue
            }

            if line.hasPrefix("[") && line.hasSuffix("]") {
                currentSection = String(line.dropFirst().dropLast()).lowercased()
                sections[currentSection!, default: [:]] = [:]
                continue
            }

            guard let currentSection, let separator = line.firstIndex(of: "=") else {
                continue
            }

            let key = line[..<separator].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let value = line[line.index(after: separator)...].trimmingCharacters(in: .whitespacesAndNewlines)
            sections[currentSection, default: [:]][key] = value
        }

        return sections
    }

    private static func parsePort(_ value: String?) throws -> Int? {
        guard let value, !value.isEmpty else {
            return nil
        }

        guard let port = Int(value) else {
            throw VirtViewerParseError.invalidPort(value)
        }

        return port
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

    private static func caCertificatePath(from value: String?) -> String? {
        guard let value, !value.contains("-----BEGIN CERTIFICATE-----") else {
            return nil
        }

        return value
    }

    private static func caCertificatePEM(from value: String?) -> String? {
        guard let value, value.contains("-----BEGIN CERTIFICATE-----") else {
            return nil
        }

        return value.replacingOccurrences(of: "\\n", with: "\n")
    }
}
