// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MacSlimManager",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacSlimManager", targets: ["MacSlimManager"])
    ],
    targets: [
        .executableTarget(
            name: "MacSlimManager"
        )
    ]
)
