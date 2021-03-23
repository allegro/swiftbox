import Foundation
import Metrics
import SwiftBoxLogging

private let logger = Logging.make("Metrics")

public final class LoggerMetricsHandler: BaseMetricsHandler {
    private let path: String

    public init(path: String) {
        self.path = path
    }

    public func getMetricPath() -> String {
        path
    }

    public func sendMetric(metric: StatsDMetric) {
        logger.debug("\(metric)")
    }
}
