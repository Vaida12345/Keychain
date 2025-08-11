// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Keychain",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "Keychain", targets: ["Keychain"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Vaida12345/Essentials.git", from: "1.1.4"),
    ],
    targets: [
        .target(name: "Keychain", dependencies: ["Essentials"]),
        .testTarget(name: "KeychainTests", dependencies: ["Keychain"]),
    ]
)
