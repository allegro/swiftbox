import Metrics

public protocol MetricsHandler: CounterHandler, TimerHandler, RecorderHandler {}
public typealias MetricsHandlerFactory = (String) -> MetricsHandler

public protocol BaseMetricsHandler: MetricsHandler {
    func getMetricPath() -> String
    func sendMetric(metric: StatsDMetric)
}

public extension BaseMetricsHandler {
    func increment(by value: Int64) {
        sendMetric(metric: CounterMetric(name: getMetricPath(), value: value))
    }

    func reset() {}

    func record(_ value: Int64) {
        record(Double(value))
    }

    func record(_ value: Double) {
        sendMetric(metric: GaugeMetric(name: getMetricPath(), value: value, type: .set))
    }

    func recordNanoseconds(_ duration: Int64) {
        recordMiliseconds(Double(duration) / 1_000_000.0)
    }

    internal func recordMiliseconds(_ duration: Double) {
        sendMetric(metric: TimerMetric(name: getMetricPath(), value: Double(duration)))
    }
}
