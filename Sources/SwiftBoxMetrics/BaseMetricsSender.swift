import Metrics

public protocol BaseMetricsSender: CounterHandler, RecorderHandler, TimerHandler {
    func getMetricPath() -> String
    func sendMetric(metric: StatsDMetric)
}

extension BaseMetricsSender {
    public func increment(by: Int64) {
        self.sendMetric(metric: CounterMetric(name: self.getMetricPath(), value: by))
    }
    public func reset() {
        fatalError("Reset is not supported")
    }

    public func record(_ value: Int64) {
        self.record(Double(value))
    }
    public func record(_ value: Double) {
        self.sendMetric(metric: GaugeMetric(name: self.getMetricPath(), value: value, type: .set))
    }

    public func recordNanoseconds(_ duration: Int64) {
        self.recordMiliseconds(Double(duration) / 1_000_000.0)
    }
    internal func recordMiliseconds(_ duration: Double) {
        self.sendMetric(metric: TimerMetric(name: self.getMetricPath(), value: Double(duration)))
    }
}
