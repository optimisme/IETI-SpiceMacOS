// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SpiceClient",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SpiceClient", targets: ["SpiceClient"]),
        .library(name: "SpiceCore", targets: ["SpiceCore"])
    ],
    targets: [
        .target(
            name: "SpiceCore",
            path: "Sources/SpiceCore"
        ),
        .executableTarget(
            name: "SpiceClient",
            dependencies: ["SpiceCore"],
            path: "Sources/SpiceClient"
        ),
        .testTarget(
            name: "SpiceCoreTests",
            dependencies: ["SpiceCore"],
            path: "Tests/SpiceCoreTests",
            resources: [
                .copy("Fixtures")
            ]
        )
    ]
)
