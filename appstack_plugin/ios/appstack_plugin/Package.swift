// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "appstack_plugin",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "appstack-plugin",
            targets: ["appstack_plugin"]
        ),
    ],
    dependencies: [
        // Reference the official Appstack iOS SDK from GitHub
        // Using exact version to ensure consistency across builds
        .package(url: "https://github.com/appstack-tech/ios-appstack-sdk.git", exact: "3.5.0"),
    ],
    targets: [
        .target(
            name: "appstack_plugin",
            dependencies: [
                .product(name: "AppstackSDK", package: "ios-appstack-sdk")
            ],
            path: "Sources/appstack_plugin",
            cSettings: [
                .define("DEFINES_MODULE", to: "YES"),
            ],
            linkerSettings: [
                .linkedFramework("UIKit"),
                .linkedFramework("Foundation"),
            ]
        ),
    ]
)
