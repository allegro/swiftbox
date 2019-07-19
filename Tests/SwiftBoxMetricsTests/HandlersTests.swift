import Foundation
import XCTest

@testable import NIO
@testable import Metrics
@testable import SwiftBoxMetrics

class StatsDHandlerTests: XCTestCase {

    class FakeStatsDClient: StatsDClientProtocol {
        public var gatheredMetrics: Array<String> = []

        func pushMetric(metricLine: String) {
            self.gatheredMetrics.append(metricLine)
        }
    }

    func testHandlerShouldGatherTimerMetricsProperly() throws {
        let handler = try StatsDMetricsHandler(
                baseMetricPath: "test.path",
                client: FakeStatsDClient()
        )
        let timer = handler.makeTimer(label: "sample.timer", dimensions: [])
        timer.recordNanoseconds(1_010_000)

        let fakeClient = (handler.client as! FakeStatsDClient)
        let metric = fakeClient.gatheredMetrics[0]
        XCTAssertEqual(metric, "test.path.sample.timer:1.01|ms")
    }

    func testHandlerShouldGatherRecorderMetricsProperly() throws {
        let handler = try StatsDMetricsHandler(
            baseMetricPath: "test.path",
            client: FakeStatsDClient()
        )
        let recorder = handler.makeRecorder(label: "sample.recorder", dimensions: [], aggregate: false)
        recorder.record(Int64(11))

        let fakeClient = (handler.client as! FakeStatsDClient)
        let metric = fakeClient.gatheredMetrics[0]
        XCTAssertEqual(metric, "test.path.sample.recorder:11.0|g")
    }

    func testHandlerShouldGatherCounterMetricsProperly() throws {
        let handler = try StatsDMetricsHandler(
            baseMetricPath: "test.path",
            client: FakeStatsDClient()
        )

        let counter = handler.makeCounter(label: "sample.counter", dimensions: [])
        counter.increment(by: 11)

        let fakeClient = (handler.client as! FakeStatsDClient)
        let metric = fakeClient.gatheredMetrics[0]
        XCTAssertEqual(metric, "test.path.sample.counter:11|c")
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
            ("testHandlerShouldGatherTimerMetricsProperly", testHandlerShouldGatherTimerMetricsProperly),
            ("testHandlerShouldGatherRecorderMetricsProperly", testHandlerShouldGatherRecorderMetricsProperly),
            ("testHandlerShouldGatherCounterMetricsProperly", testHandlerShouldGatherCounterMetricsProperly),
            ("testHandlerShouldValidateBasePath", testHandlerShouldValidateBasePath),
            ("testHandlerShouldThrowWhenBasePathIsWrong", testHandlerShouldThrowWhenBasePathIsWrong),
        ]
    }
}
