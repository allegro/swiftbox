import Foundation
import Metrics
import SwiftBoxLogging

private var logger = Logging.make("Metrics")


/// Metrics handler that logs gathered metrics
public final class LoggerMetricsHandler: MetricsFactory {

    public init() {}

    public func makeCounter(label: String, dimensions: [(String, String)]) -> CounterHandler {
        return LoggerMetricsSender(path: label)
    }
    public func makeRecorder(label: String, dimensions: [(String, String)], aggregate: Bool) -> RecorderHandler {
        return LoggerMetricsSender(path: label)
    }
    public func makeTimer(label: String, dimensions: [(String, String)]) -> TimerHandler {
        return LoggerMetricsSender(path: label)
    }

    public func destroyCounter(_: CounterHandler) {}
    public func destroyRecorder(_: RecorderHandler) {}
    public func destroyTimer(_: TimerHandler) {}
}

public final class LoggerMetricsSender: BaseMetricsSender {
    private let path: String

    public init(path: String) {
        self.path = path
    }

    public func getMetricPath() -> String {
        return self.path
    }

    public func sendMetric(metric: StatsDMetric) {
        logger.debug("\(metric)")
    }
}
