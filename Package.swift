// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Kofein",
    defaultLocalization: "en",
    platforms: [.macOS("26.0")],
    targets: [
        .target(
            name: "KofeinCore",
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "Kofein",
            dependencies: ["KofeinCore"]
        ),
        .testTarget(
            name: "KofeinCoreTests",
            dependencies: ["KofeinCore"]
        ),
    ]
)
