// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ScClientNative",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(
            name: "ScClientNative",
            targets: ["ScClientNative"]),
    ],
    targets: [
        .target(
            name: "ScClientNative"),
        .testTarget(
            name: "ScClientNativeTests",
            dependencies: ["ScClientNative"]
        ),
    ]
)
