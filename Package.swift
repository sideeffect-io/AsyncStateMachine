// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "AsyncStateMachine",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "AsyncStateMachine",
            targets: ["AsyncStateMachine"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AsyncStateMachine",
            dependencies: [],
            path: "Sources"),
        .testTarget(
            name: "AsyncStateMachineTests",
            dependencies: ["AsyncStateMachine"],
            path: "Tests"),
    ]
)