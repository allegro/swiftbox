// swift-tools-version:5.3

import PackageDescription

let package = Package(
        name: "SwiftBox",
        platforms: [
                .macOS(.v10_15)
        ],
        products: [
                .library(name: "SwiftBoxLogging", type: .static, targets: ["SwiftBoxLogging"]),
                .library(name: "SwiftBoxMetrics", type: .static, targets: ["SwiftBoxMetrics"]),
                .library(name: "SwiftBoxConfig", type: .static, targets: ["SwiftBoxConfig"])
        ],
        dependencies: [
                .package(
                        name: "swift-nio-ssl",
                        url: "https://github.com/apple/swift-nio-ssl",
                        from: "2.23.1"
                ),
                .package(
                        url: "https://github.com/apple/swift-metrics.git", "1.0.0" ..< "3.0.0"
                ),
                .package(
                        url: "https://github.com/apple/swift-log.git",
                        from: "1.0.0"
                ),
                .package(
                        name: "SwiftTestReporter",
                        url: "https://github.com/allegro/swift-junit.git",
                        from: "2.0.0"
                )
        ],
        targets: [
                .target(
                        name: "SwiftBoxLogging",
                        dependencies: [
                                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                                .product(name: "Logging", package: "swift-log")
                        ]
                ),
                .testTarget(
                        name: "SwiftBoxLoggingTests",
                        dependencies: ["SwiftBoxLogging", "SwiftTestReporter"]
                ),

            .target(
                    name: "SwiftBoxMetrics",
                    dependencies: ["SwiftBoxLogging", .product(name: "Metrics", package: "swift-metrics")]
            ),
                .testTarget(
                        name: "SwiftBoxMetricsTests",
                        dependencies: ["SwiftBoxMetrics", "SwiftTestReporter"]
                ),

            .target(name: "SwiftBoxConfig",
                    dependencies: ["SwiftBoxLogging"]),
                .testTarget(
                        name: "SwiftBoxConfigTests",
                        dependencies: ["SwiftBoxConfig", "SwiftTestReporter"]
                )
        ]
)
