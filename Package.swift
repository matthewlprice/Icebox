// swift-tools-version:4.0
// Managed by ice

import PackageDescription

let package = Package(
    name: "Beach",
    products: [
        .library(name: "Beach", targets: ["Beach"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kylef/PathKit", from: "0.9.1"),
    ],
    targets: [
        .target(name: "Beach", dependencies: ["PathKit"]),
        .testTarget(name: "BeachTests", dependencies: ["Beach"]),
    ]
)
