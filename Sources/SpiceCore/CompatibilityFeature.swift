import Foundation

public struct CompatibilityFeature: Identifiable, Equatable, Sendable {
    public var id: String { name }
    public var name: String
    public var status: CompatibilityStatus
    public var details: String
    public var validationStatus: String

    public init(
        name: String,
        status: CompatibilityStatus,
        details: String,
        validationStatus: String
    ) {
        self.name = name
        self.status = status
        self.details = details
        self.validationStatus = validationStatus
    }
}

public enum CompatibilityStatus: String, Equatable, Sendable {
    case delegated = "Delegated"
    case planned = "Planned"
    case unknown = "Needs validation"
}

public enum CompatibilityMatrix {
    public static let current: [CompatibilityFeature] = [
        CompatibilityFeature(
            name: "Display",
            status: .delegated,
            details: "Rendered by remote-viewer in v1.",
            validationStatus: "Needs real SPICE server validation."
        ),
        CompatibilityFeature(
            name: "Keyboard and Mouse",
            status: .delegated,
            details: "Handled by remote-viewer and the SPICE server.",
            validationStatus: "Needs real SPICE server validation."
        ),
        CompatibilityFeature(
            name: "Clipboard Copy/Paste",
            status: .delegated,
            details: "Expected through remote-viewer when the SPICE server allows clipboard sharing and the guest has a running SPICE guest agent such as spice-vdagent.",
            validationStatus: "Validated with the Isard .vv session through Homebrew spice-gtk / spicy."
        ),
        CompatibilityFeature(
            name: "Audio",
            status: .delegated,
            details: "Handled by remote-viewer, SPICE audio channels, and backend runtime dependencies.",
            validationStatus: "Needs real SPICE server validation."
        ),
        CompatibilityFeature(
            name: "USB Redirection",
            status: .unknown,
            details: "Depends on remote-viewer, server policy, guest support, and macOS packaging of USB-related dependencies.",
            validationStatus: "Not validated."
        ),
        CompatibilityFeature(
            name: "Native Embedded View",
            status: .planned,
            details: "Deferred until after helper-process mode is proven.",
            validationStatus: "Not started."
        )
    ]
}
