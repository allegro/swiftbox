import Foundation
import XCTest

@testable import NIO
@testable import SwiftBoxMetrics


class FakeHandler: MetricsHandler {
    var gatheredMetrics: [Metric] = []

    func sendMetric(metric: Metric) {
        self.gatheredMetrics.append(metric)
    }
}

class MetricsHandlerTests: XCTestCase {

    func testHandlerWithTimerShouldRecordTimeCorrectly() throws {
        let metricName = "test.label"
        let sleepTime = 2.0

        Metrics.bootstrap(FakeHandler())

        Metrics.global.withTimer(name: metricName) {
            Thread.sleep(forTimeInterval: sleepTime)
        }

        let metric = (Metrics.global as! FakeHandler).gatheredMetrics[0] as! TimerMetric
        XCTAssertEqual(metric.name, metricName)
        XCTAssertEqual(metric.value, sleepTime * 1000, accuracy: 20)
    }

    static var allTests: [(String, (MetricsHandlerTests) -> () throws -> Void)] {
        return [
            ("testHandlerWithTimerShouldRecordTimeCorrectly", testHandlerWithTimerShouldRecordTimeCorrectly),
        ]
    }
}

class StatsDHandlerTests: XCTestCase {

    class FakeStatsDClient: StatsDClientProtocol {
        public var gatheredMetrics: Array<String> = []

        func pushMetric(metricLine: String) {
            self.gatheredMetrics.append(metricLine)
        }
    }

    func testHandlerShouldGatherMetricsProperly() throws {
        let handler = try StatsDMetricsHandler(
                baseMetricPath: "test.path",
                client: FakeStatsDClient()
        )
        handler.sendMetric(metric: TimerMetric(name: "test", value: 1.01))

        let fakeClient = (handler.client as! FakeStatsDClient)
        let metric = fakeClient.gatheredMetrics[0]
        XCTAssertEqual(metric, "test.path.test:1.01|ms")
    }

    func testHandlerShouldValidateBasePath() throws {
        XCTAssertTrue(StatsDMetricsHandler.validateBasePath("example"))
        XCTAssertTrue(StatsDMetricsHandler.validateBasePath("example.com"))
        XCTAssertTrue(StatsDMetricsHandler.validateBasePath("example.com.test"))
        XCTAssertTrue(StatsDMetricsHandler.validateBasePath("example.com.test"))

        XCTAssertFalse(StatsDMetricsHandler.validateBasePath("example..com"))
        XCTAssertFalse(StatsDMetricsHandler.validateBasePath("example.com."))
        XCTAssertFalse(StatsDMetricsHandler.validateBasePath("example com test"))
    }

    func testHandlerShouldThrowWhenBasePathIsWrong() throws {
        XCTAssertThrowsError(try StatsDMetricsHandler(baseMetricPath: "example.", client: FakeStatsDClient())) { error in
            XCTAssertTrue(error is InvalidConfigurationError)
            XCTAssertTrue((error as! InvalidConfigurationError).message.contains("Invalid base path"))
        }
    }

    static var allTests: [(String, (StatsDHandlerTests) -> () throws -> Void)] {
        return [
            ("testHandlerShouldGatherMetricsProperly", testHandlerShouldGatherMetricsProperly),
            ("testHandlerShouldValidateBasePath", testHandlerShouldValidateBasePath),
            ("testHandlerShouldThrowWhenBasePathIsWrong", testHandlerShouldThrowWhenBasePathIsWrong),
        ]
    }
}