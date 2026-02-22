// swift-tools-version: 5.9
import PackageDescription

// NOTE: This Package.swift is provided for code organization and test compilation.
// To build the full iOS app with SwiftUI previews and device deployment,
// create an Xcode project (File > New > Project > App) and drag in the
// Reflect/ source folder. The app entry point is ReflectApp.swift.
//
// Alternatively, open this folder in Xcode and it will recognize the package.

let package = Package(
    name: "Reflect",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ReflectLib",
            targets: ["ReflectLib"]
        ),
    ],
    targets: [
        // Core library (models, services, view models — no @main)
        .target(
            name: "ReflectLib",
            dependencies: [],
            path: "Reflect",
            exclude: ["Info.plist", "ReflectApp.swift"],
            swiftSettings: [
                .define("SWIFT_PACKAGE"),
            ]
        ),
        // Tests
        .testTarget(
            name: "ReflectTests",
            dependencies: ["ReflectLib"],
            path: "ReflectTests"
        ),
    ]
)
