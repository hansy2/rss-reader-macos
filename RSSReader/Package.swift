// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "RSSReader",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/nmdias/FeedKit.git", from: "9.1.2"),
    ],
    targets: [
        .executableTarget(
            name: "RSSReader",
            dependencies: ["FeedKit"],
            path: ".",
            sources: ["RSSReader", "Shared"]
        ),
    ]
)
