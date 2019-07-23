import Foundation
import Metrics

public final class StatsDMetricsHandler: BaseMetricsHandler {
    private let path: String
    private let client: StatsDClientProtocol

    public init(
        path: String,
        client: StatsDClientProtocol
    ) {
        self.path = path
        self.client = client
    }

    public func getMetricPath() -> String {
        return self.path
    }

    public func sendMetric(metric: StatsDMetric) {
        client.pushMetric(metricLine: metric.getStatsDLine())
    }
}
