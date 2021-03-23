import Foundation
import XCTest

@testable import Metrics
@testable import NIO
@testable import SwiftBoxMetrics

class StatsDHandlerTests: XCTestCase {
    class FakeStatsDClient: StatsDClientProtocol {
        public var gatheredMetrics: [String] = []

        func pushMetric(metricLine: String) {
            gatheredMetrics.append(metricLine)
        }
    }

    func testHandlerShouldGatherTimerMetrics() throws {
        let client = FakeStatsDClient()
        let handler = try StatsDMetricsFactory(
                baseMetricPath: "com.allegro"
        ) { path in
            StatsDMetricsHandler(path: path, client: client)
        }
        let timer = handler.makeTimer(label: "stats.timer", dimensions: [])
        timer.recordNanoseconds(1_010_000)

        let metric = client.gatheredMetrics[0]
        XCTAssertEqual(metric, "com.allegro.stats.timer:1.01|ms")
    }

    func testHandlerShouldGatherRecorderMetrics() throws {
        let client = FakeStatsDClient()
        let handler = try StatsDMetricsFactory(
            baseMetricPath: "com.allegro"
        ) { path in
            StatsDMetricsHandler(path: path, client: client)
        }
        let recorder = handler.makeRecorder(label: "stats.recorder", dimensions: [], aggregate: false)
        recorder.record(Int64(11))

        let metric = client.gatheredMetrics[0]
        XCTAssertEqual(metric, "com.allegro.stats.recorder:11.0|g")
    }

    func testHandlerShouldGatherCounterMetrics() throws {
        let client = FakeStatsDClient()
        let handler = try StatsDMetricsFactory(
            baseMetricPath: "com.allegro"
        ) { path in
            StatsDMetricsHandler(path: path, client: client)
        }

        let counter = handler.makeCounter(label: "stats.counter", dimensions: [])
        counter.increment(by: 11)

        let metric = client.gatheredMetrics[0]
        XCTAssertEqual(metric, "com.allegro.stats.counter:11|c")
    }

    func testHandlerShouldValidateBasePath() throws {
        XCTAssertTrue(StatsDMetricsFactory.validateBasePath("example"))
        XCTAssertTrue(StatsDMetricsFactory.validateBasePath("example.com"))
        XCTAssertTrue(StatsDMetricsFactory.validateBasePath("example.com.test"))
        XCTAssertTrue(StatsDMetricsFactory.validateBasePath("example.com.test"))

        XCTAssertFalse(StatsDMetricsFactory.validateBasePath("example..com"))
        XCTAssertFalse(StatsDMetricsFactory.validateBasePath("example.com."))
        XCTAssertFalse(StatsDMetricsFactory.validateBasePath("example com test"))
    }

    func testHandlerShouldThrowWhenBasePathIsWrong() throws {
        let client = FakeStatsDClient()
        XCTAssertThrowsError(
            try StatsDMetricsFactory(
                baseMetricPath: "com."
            ) { path in
                StatsDMetricsHandler(path: path, client: client)
            }
        ) { error in
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
            ("testHandlerShouldThrowWhenBasePathIsWrong", testHandlerShouldThrowWhenBasePathIsWrong)
        ]
    }
}
