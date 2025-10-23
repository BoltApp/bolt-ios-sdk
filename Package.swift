// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BoltSDK",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "BoltSDK", targets: ["BoltSDK"]),
    ],
    targets: [
        .target(
            name: "BoltSDK",
            dependencies: []),
        .testTarget(
            name: "BoltSDKTests",
            dependencies: ["BoltSDK"]),
    ]
)