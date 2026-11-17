// swift-tools-version: 6.0
//
// Unshell native macOS app. Built with SwiftPM (no .xcodeproj) and bundled into
// Unshell.app by `just mac-app`. GhosttyKit.xcframework is produced by
// `just ghostty-kit` and copied into Vendor/ (gitignored).

import PackageDescription

let package = Package(
    name: "UnshellMac",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Unshell", targets: ["Unshell"]),
    ],
    targets: [
        .binaryTarget(
            name: "GhosttyKit",
            path: "Vendor/GhosttyKit.xcframework"
        ),
        .executableTarget(
            name: "Unshell",
            dependencies: ["GhosttyKit"],
            path: "Sources/Unshell",
            swiftSettings: [
                // C callbacks from libghostty are not Sendable-annotated; stay on
                // Swift 5 language mode until the bridge is isolated properly.
                .swiftLanguageMode(.v5),
            ],
            linkerSettings: [
                .linkedLibrary("c++"),
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("CoreText"),
                .linkedFramework("CoreVideo"),
                .linkedFramework("IOSurface"),
                .linkedFramework("Metal"),
                .linkedFramework("QuartzCore"),
                .linkedFramework("UniformTypeIdentifiers"),
            ]
        ),
    ]
)
