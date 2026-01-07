// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Vimualizer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Vimualizer", targets: ["Vimualizer"]),
    ],
    targets: [
        .executableTarget(
            name: "Vimualizer",
            dependencies: [],
            path: "Sources/Vimualizer",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        ),
    ]
)
