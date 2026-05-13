import Foundation

public struct OpenSourceNotice: Identifiable, Equatable, Sendable {
    public var id: String { name }
    public var name: String
    public var role: String
    public var license: String
    public var distributionNotes: String
    public var sourceURL: URL

    public init(
        name: String,
        role: String,
        license: String,
        distributionNotes: String,
        sourceURL: URL
    ) {
        self.name = name
        self.role = role
        self.license = license
        self.distributionNotes = distributionNotes
        self.sourceURL = sourceURL
    }
}

public enum OpenSourceNotices {
    public static let current: [OpenSourceNotice] = [
        OpenSourceNotice(
            name: "spice-gtk / spicy",
            role: "Current SPICE backend helper process for source installs",
            license: "Homebrew reports GPL-2.0-or-later AND LGPL-2.1-or-later AND BSD-3-Clause",
            distributionNotes: "Current builds expect users to install this with Homebrew. Bundling requires license notices, source access or source offer, and dependency notices.",
            sourceURL: URL(string: "https://gitlab.freedesktop.org/spice/spice-gtk")!
        ),
        OpenSourceNotice(
            name: "virt-viewer / remote-viewer",
            role: "Optional SPICE backend helper process",
            license: "GPL-2.0-or-later, verify exact shipped version before bundling",
            distributionNotes: "Not available from Homebrew in this environment. If used later, prefer user-installed binaries or handle GPL redistribution obligations.",
            sourceURL: URL(string: "https://gitlab.com/virt-viewer/virt-viewer")!
        ),
        OpenSourceNotice(
            name: "spice-client-glib",
            role: "Future native SPICE integration candidate",
            license: "Verify exact package/file licenses before linking",
            distributionNotes: "Prefer dynamic linking if used later. Redistributed libraries require applicable GPL/LGPL notices and source references.",
            sourceURL: URL(string: "https://gitlab.freedesktop.org/spice/spice-gtk")!
        ),
        OpenSourceNotice(
            name: "GStreamer",
            role: "Potential audio/media runtime dependency",
            license: "LGPL with plugin-specific caveats",
            distributionNotes: "Bundled plugin sets must be audited separately because plugins may introduce extra license or patent constraints.",
            sourceURL: URL(string: "https://gstreamer.freedesktop.org/documentation/application-development/appendix/licensing.html")!
        ),
        OpenSourceNotice(
            name: "GTK / GLib",
            role: "Runtime stack for GTK-based SPICE clients",
            license: "LGPL-family, verify exact packages before bundling",
            distributionNotes: "Bundling GTK runtime libraries requires notices, source references, and version tracking.",
            sourceURL: URL(string: "https://www.gtk.org/")!
        )
    ]
}
