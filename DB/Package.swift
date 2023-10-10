// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "DB",
    platforms: [
        .iOS(.v15),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "DB",
            targets: ["DB"])
    ],
    dependencies: [
        .package(name: "GRDB", url: "https://github.com/metabolist/GRDB.swift.git", .revision("a6ff285")),
        .package(path: "Mastodon"),
        .package(path: "Secrets")
    ],
    targets: [
        .target(
            name: "DB",
            dependencies: ["GRDB", "Mastodon", "Secrets"]),
        .testTarget(
            name: "DBTests",
            dependencies: ["DB"])
    ]
)
