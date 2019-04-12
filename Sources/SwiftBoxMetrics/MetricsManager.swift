import Foundation

import SwiftBoxLogging

private var logger = Logging.make(#file)

/// Global Metrics manager
/// Compatible with Swift Metrics Proposal
public enum Metrics {
    /// Global metrics handler
    private static var handler: MetricsHandler = LoggerMetricsHandler()

    /// Bootstrap method used to overwrite default handler.
    /// It is intended to be ran before app initializes
    public static func bootstrap(_ handler: MetricsHandler) {
        self.handler = handler
    }

    /// Global handler instance getter
    public static var global: MetricsHandler {
        return handler
    }
}
