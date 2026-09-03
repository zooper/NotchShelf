// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NotchShelf",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "NotchShelf", targets: ["NotchShelf"])
    ],
    targets: [
        .executableTarget(
            name: "NotchShelf",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices")
            ]
        ),
        .testTarget(
            name: "NotchShelfTests",
            dependencies: ["NotchShelf"]
        )
    ]
)
