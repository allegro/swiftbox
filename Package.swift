// swift-tools-version:4.2

import PackageDescription

let package = Package(
        name: "SwiftBox",

        products: [
            .library(name: "SwiftBoxLogging", type: .static, targets: ["SwiftBoxLogging"]),
            .library(name: "SwiftBoxMetrics", type: .static, targets: ["SwiftBoxMetrics"]),
            .library(name: "SwiftBoxConfig", type: .static, targets: ["SwiftBoxConfig"]),
        ],
        dependencies: [
            .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
            .package(url: "https://github.com/allegro/swift-junit.git", from: "1.0.0"),
        ],

        targets: [
            .target(
                    name: "SwiftBoxLogging",
                    dependencies: ["Vapor"]
            ),
            .testTarget(
                    name: "SwiftBoxLoggingTests",
                    dependencies: ["SwiftBoxLogging", "SwiftTestReporter"]
            ),

            .target(
                    name: "SwiftBoxMetrics",
                    dependencies: ["SwiftBoxLogging"]
            ),
            .testTarget(
                    name: "SwiftBoxMetricsTests",
                    dependencies: ["SwiftBoxMetrics", "SwiftTestReporter"]
            ),

            .target(name: "SwiftBoxConfig",
                    dependencies: ["SwiftBoxLogging"]
            ),
            .testTarget(
                    name: "SwiftBoxConfigTests",
                    dependencies: ["SwiftBoxConfig", "SwiftTestReporter"]
            ),
        ]
)
