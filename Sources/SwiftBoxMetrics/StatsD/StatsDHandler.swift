import Foundation

/// Metrics handler that sends gathered metrics to StatsD server
/// - parameter baseMetricPath Base path for all metrics, will be prepended to every metric sent to StatsD
/// - parameter client: StatsD client
public class StatsDMetricsHandler: MetricsHandler {
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

    /// Prepends base path to metric name and passes it to StatsD Client
    public func sendMetric(metric: Metric) {
        guard let statsDMetric = metric as? StatsDMetric else {
            fatalError("Metric must conform to StatsDMetric to use with StatsD handler")
        }
        client.pushMetric(metricLine: "\(baseMetricPath).\(statsDMetric.getStatsDLine())")
    }
}

public struct InvalidConfigurationError: Error {
    let message: String
}