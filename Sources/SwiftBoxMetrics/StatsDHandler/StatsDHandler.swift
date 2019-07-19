import Foundation
import Metrics
public struct InvalidConfigurationError: Error {
    let message: String
}

/// Metrics handler that sends gathered metrics to StatsD server
/// - parameter baseMetricPath Base path for all metrics, will be prepended to every metric sent to StatsD
/// - parameter client: StatsD client
public final class StatsDMetricsHandler: MetricsFactory {
    let baseMetricPath: String
    let client: StatsDClientProtocol
    static let basePathRegex = "^[a-z]+(?:\\.[a-z]+)*$"
    static let basePathTest = try! NSRegularExpression(pattern: basePathRegex, options: .caseInsensitive)

    public init(
        baseMetricPath: String,
        client: StatsDClientProtocol
    ) throws {
        guard StatsDMetricsHandler.validateBasePath(baseMetricPath) else {
            throw InvalidConfigurationError(message: "Invalid base path \(baseMetricPath), base path should consist only of small letters and dots, sample: example.com.test")
        }
        self.baseMetricPath = baseMetricPath
        self.client = client
    }

    internal static func validateBasePath(_ path: String) -> Bool {
        return basePathTest.matches(in: path, range: NSMakeRange(0, path.utf8.count)).count > 0
    }

    public func makeCounter(label: String, dimensions: [(String, String)]) -> CounterHandler {
        return StatsDMetricsSender(path: "\(baseMetricPath).\(label)", client: self.client)
    }
    public func makeRecorder(label: String, dimensions: [(String, String)], aggregate: Bool) -> RecorderHandler {
        return StatsDMetricsSender(path: "\(baseMetricPath).\(label)", client: self.client)
    }
    public func makeTimer(label: String, dimensions: [(String, String)]) -> TimerHandler {
        return StatsDMetricsSender(path: "\(baseMetricPath).\(label)", client: self.client)
    }

    public func destroyCounter(_: CounterHandler) {}
    public func destroyRecorder(_: RecorderHandler) {}
    public func destroyTimer(_: TimerHandler) {}
}

public final class StatsDMetricsSender: BaseMetricsSender {
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
