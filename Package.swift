// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SkSocketSwift",
    platforms: [.iOS(.v13), .macOS(.v12)],
    products: [
        .library(
            name: "SkSocketSwift",
            targets: ["SkSocketSwift"]),
    ],
    targets: [
        .target(
            name: "SkSocketSwift"),
        .testTarget(
            name: "SkSocketSwiftTests",
            dependencies: ["SkSocketSwift"]
        ),
    ]
)
