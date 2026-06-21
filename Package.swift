// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "KindleShare",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "kindle-share", targets: ["KindleShareCLI"]),
        .executable(name: "KindleShare", targets: ["KindleShareApp"]),
        .library(name: "KindleShareCore", targets: ["KindleShareCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.80.0")
    ],
    targets: [
        .target(
            name: "KindleShareCore",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio")
            ],
            path: "Sources/KindleShareCore"
        ),
        .executableTarget(
            name: "KindleShareApp",
            dependencies: ["KindleShareCore"],
            path: "Sources/KindleShareApp"
        ),
        .executableTarget(
            name: "KindleShareCLI",
            dependencies: ["KindleShareCore"],
            path: "Sources/KindleShareCLI"
        ),
        .testTarget(
            name: "KindleShareCoreTests",
            dependencies: ["KindleShareCore"],
            path: "Tests/KindleShareCoreTests"
        ),
        .testTarget(
            name: "KindleShareCLITests",
            dependencies: ["KindleShareCLI"],
            path: "Tests/KindleShareCLITests"
        )
    ]
)
