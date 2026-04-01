// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Enkadr",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Enkadr",
            dependencies: ["EnkadrKit"],
            path: "Enkadr",
            exclude: ["Info.plist", "Assets.xcassets"]
        ),
        .target(
            name: "EnkadrKit",
            path: "EnkadrKit"
        ),
        .testTarget(
            name: "EnkadrKitTests",
            dependencies: ["EnkadrKit"],
            path: "Tests"
        ),
    ]
)
