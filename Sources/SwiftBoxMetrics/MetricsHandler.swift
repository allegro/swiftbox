import Foundation

import SwiftBoxLogging

private var logger = Logging.make(#file)

public protocol MetricsHandler {
    func sendMetric(metric: Metric)
}

public extension MetricsHandler {
    /// Helper method to automatically measure time of completion for given closure
    func withTimer<T>(name: String, function: () throws -> T) rethrows -> T {
        let start = Date()
        let result = try function()
        let elapsed = Date().timeIntervalSince(start) * 1000
        sendMetric(metric: TimerMetric(name: name, value: elapsed))
        return result
    }
}

/// Default metrics handler that logs all gathered metrics to console
public class LoggerMetricsHandler: MetricsHandler {
    public func sendMetric(metric: Metric) {
        logger.debug("LoggerMetricsHandler: \(metric)")
    }
}
