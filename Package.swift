// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KinesiaMotion",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "KinesiaMotion", targets: ["KinesiaMotion"]),
        .library(name: "KinesiaMotionVision", targets: ["KinesiaMotionVision"])
    ],
    targets: [
        .target(name: "KinesiaMotion"),
        .target(name: "KinesiaMotionVision", dependencies: ["KinesiaMotion"]),
        .testTarget(name: "KinesiaMotionTests", dependencies: ["KinesiaMotion"]),
        .testTarget(name: "KinesiaMotionVisionTests", dependencies: ["KinesiaMotionVision"])
    ]
)
