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

    func testHandlerShouldGatherTimerMetrics() throws {
        let handler = try StatsDMetricsHandler(
                baseMetricPath: "com.allegro",
                client: FakeStatsDClient()
        )
        let timer = handler.makeTimer(label: "stats.timer", dimensions: [])
        timer.recordNanoseconds(1_010_000)

        let fakeClient = (handler.client as! FakeStatsDClient)
        let metric = fakeClient.gatheredMetrics[0]
        XCTAssertEqual(metric, "com.allegro.stats.timer:1.01|ms")
    }

    func testHandlerShouldGatherRecorderMetrics() throws {
        let handler = try StatsDMetricsHandler(
            baseMetricPath: "com.allegro",
            client: FakeStatsDClient()
        )
        let recorder = handler.makeRecorder(label: "stats.recorder", dimensions: [], aggregate: false)
        recorder.record(Int64(11))

        let fakeClient = (handler.client as! FakeStatsDClient)
        let metric = fakeClient.gatheredMetrics[0]
        XCTAssertEqual(metric, "com.allegro.stats.recorder:11.0|g")
    }

    func testHandlerShouldGatherCounterMetrics() throws {
        let handler = try StatsDMetricsHandler(
            baseMetricPath: "com.allegro",
            client: FakeStatsDClient()
        )

        let counter = handler.makeCounter(label: "stats.counter", dimensions: [])
        counter.increment(by: 11)

        let fakeClient = (handler.client as! FakeStatsDClient)
        let metric = fakeClient.gatheredMetrics[0]
        XCTAssertEqual(metric, "com.allegro.stats.counter:11|c")
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
            ("testHandlerShouldGatherTimerMetrics", testHandlerShouldGatherTimerMetrics),
            ("testHandlerShouldGatherRecorderMetrics", testHandlerShouldGatherRecorderMetrics),
            ("testHandlerShouldGatherCounterMetrics", testHandlerShouldGatherCounterMetrics),
            ("testHandlerShouldValidateBasePath", testHandlerShouldValidateBasePath),
            ("testHandlerShouldThrowWhenBasePathIsWrong", testHandlerShouldThrowWhenBasePathIsWrong),
        ]
    }
}
