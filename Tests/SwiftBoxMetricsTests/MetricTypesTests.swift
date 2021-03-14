import Foundation
import XCTest

@testable import SwiftBoxMetrics

class MetricTypesTests: XCTestCase {
    func testTimerStatsDFormat() throws {
        let metric = TimerMetric(name: "test", value: 1.001)

        XCTAssertEqual(metric.getStatsDLine(), "test:1.001|ms")
    }

    func testCounterStatsDFormat() throws {
        let metric = CounterMetric(name: "test", value: 2)

        XCTAssertEqual(metric.getStatsDLine(), "test:2|c")
    }

    func testGaugeStatsDFormatWhenTypeIsSet() throws {
        let metric = GaugeMetric(name: "test", value: 2, type: .set)
        XCTAssertEqual(metric.getStatsDLine(), "test:2.0|g")
    }

    func testGaugeStatsDFormatWhenTypeIsIncrement() throws {
        let metric = GaugeMetric(name: "test", value: 2, type: .increment)
        XCTAssertEqual(metric.getStatsDLine(), "test:+2.0|g")
    }

    func testGaugeStatsDFormatWhenTypeIsDecrement() throws {
        let metric = GaugeMetric(name: "test", value: 2, type: .decrement)
        XCTAssertEqual(metric.getStatsDLine(), "test:-2.0|g")
    }

    static var allTests: [(String, (MetricTypesTests) -> () throws -> Void)] {
        return [
            ("testTimerStatsDFormat", testTimerStatsDFormat),
            ("testGaugeStatsDFormatWhenTypeIsSet", testGaugeStatsDFormatWhenTypeIsSet),
            ("testGaugeStatsDFormatWhenTypeIsIncrement", testGaugeStatsDFormatWhenTypeIsIncrement),
            ("testGaugeStatsDFormatWhenTypeIsDecrement", testGaugeStatsDFormatWhenTypeIsDecrement),
            ("testCounterStatsDFormat", testCounterStatsDFormat)
        ]
    }
}
