// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HotspotMeter",
    platforms: [.macOS(.v15)],
    targets: [
        .target(name: "HotspotMeterCore"),
        .executableTarget(
            name: "HotspotMeter",
            dependencies: ["HotspotMeterCore"]
        ),
        .testTarget(
            name: "HotspotMeterCoreTests",
            dependencies: ["HotspotMeterCore"]
        ),
    ]
)
