// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "KindleShare",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "KindleShare", targets: ["KindleShareApp"]),
        .library(name: "KindleShareCore", targets: ["KindleShareCore"])
    ],
    targets: [
        .target(
            name: "KindleShareCore",
            path: "Sources/KindleShareCore"
        ),
        .executableTarget(
            name: "KindleShareApp",
            dependencies: ["KindleShareCore"],
            path: "Sources/KindleShareApp"
        ),
        .testTarget(
            name: "KindleShareCoreTests",
            dependencies: ["KindleShareCore"],
            path: "Tests/KindleShareCoreTests"
        )
    ]
)
