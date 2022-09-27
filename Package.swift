// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AsyncDispatcher",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15),
        .macOS(.v12),
        .watchOS(.v8)
    ],
    products: [
        .library(name: "AsyncDispatcher", targets: ["AsyncDispatcher"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.0.3")),
    ],
    targets: [
        .target(name: "AsyncDispatcher", dependencies: [
            .product(name: "Collections", package: "swift-collections")
        ]),
        .testTarget(name: "AsyncDispatcherTests", dependencies: [
            "AsyncDispatcher"
        ]),
    ],
    swiftLanguageVersions: [ .v5 ]
)
