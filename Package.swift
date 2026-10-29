// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DataUsage",
    platforms: [.macOS(.v15)],
    targets: [
        .target(name: "DataUsageCore"),
        .executableTarget(
            name: "DataUsage",
            dependencies: ["DataUsageCore"]
        ),
        .testTarget(
            name: "DataUsageCoreTests",
            dependencies: ["DataUsageCore"]
        ),
    ]
)
