// swift-tools-version:4.0
// Managed by ice

import PackageDescription

let package = Package(
    name: "Beach",
    products: [
        .library(name: "Beach", targets: ["Beach"]),
    ],
    targets: [
        .target(name: "Beach", dependencies: []),
        .testTarget(name: "BeachTests", dependencies: ["Beach"]),
    ]
)
