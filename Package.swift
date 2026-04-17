// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Lockey",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "LockeyKit", targets: ["LockeyKit"]),
        .executable(name: "Lockey", targets: ["Lockey"])
    ],
    targets: [
        .target(
            name: "LockeyKit"
        ),
        .executableTarget(
            name: "Lockey",
            dependencies: ["LockeyKit"]
        ),
        .testTarget(
            name: "LockeyKitTests",
            dependencies: ["LockeyKit"]
        )
    ]
)
