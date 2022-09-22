// swift-tools-version:5.5
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
    targets: [
        .target(name: "AsyncDispatcher", dependencies: []),
        .testTarget(name: "AsyncDispatcherTests", dependencies: ["AsyncDispatcher"]),
    ],
    swiftLanguageVersions: [ .v5 ]
)
