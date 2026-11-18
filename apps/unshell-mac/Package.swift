// swift-tools-version: 6.0
//
// Unshell native macOS app. Built with SwiftPM (no .xcodeproj) and bundled into
// Unshell.app by `just mac-app`. Vendored inputs (gitignored):
//   Vendor/GhosttyKit.xcframework   `just ghostty-kit`
//   Vendor/TreeSitterGrammars/      `just tree-sitter-grammars` (grammars.tsv)

import Foundation
import PackageDescription

let packageDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent().path

/// Grammar ids in grammars.tsv order. Each becomes a C target `Grammar_<id>`.
let grammars: [String] = {
    guard let manifest = try? String(contentsOfFile: packageDir + "/grammars.tsv", encoding: .utf8) else { return [] }
    return manifest.split(separator: "\n").compactMap { line in
        guard !line.hasPrefix("#"), let id = line.split(separator: "\t").first else { return nil }
        return String(id)
    }
}()

let grammarTargets: [Target] = grammars.map { id in
    let dir = "Vendor/TreeSitterGrammars/\(id)"
    let hasScanner = FileManager.default.fileExists(atPath: "\(packageDir)/\(dir)/src/scanner.c")
    return .target(
        name: "Grammar_\(id)",
        path: dir,
        // Only the parser and scanner are translation units; other .c files in
        // src/ (YAML's schemas) are #included by the scanner.
        sources: ["src/parser.c"] + (hasScanner ? ["src/scanner.c"] : []),
        publicHeadersPath: "include",
        cSettings: [
            .headerSearchPath("src"),
            .unsafeFlags(["-w", "-O2"]),
        ]
    )
}

let package = Package(
    name: "UnshellMac",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Unshell", targets: ["Unshell"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter", exact: "0.25.0"),
        .package(url: "https://github.com/CodeEditApp/CodeEditTextView", exact: "0.12.1"),
    ],
    targets: [
        .binaryTarget(
            name: "GhosttyKit",
            path: "Vendor/GhosttyKit.xcframework"
        ),
        // Code viewer core: languages, highlighting, semantic tokens. No AppKit,
        // so it is unit-testable.
        .target(
            name: "UnshellCode",
            dependencies: [.product(name: "SwiftTreeSitter", package: "SwiftTreeSitter")]
                + grammars.map { .target(name: "Grammar_\($0)") },
            path: "Sources/UnshellCode",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .executableTarget(
            name: "Unshell",
            dependencies: [
                "GhosttyKit",
                "UnshellCode",
                .product(name: "CodeEditTextView", package: "CodeEditTextView"),
            ],
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
        .testTarget(
            name: "UnshellCodeTests",
            dependencies: ["UnshellCode"],
            path: "Tests/UnshellCodeTests"
        ),
    ] + grammarTargets
)
