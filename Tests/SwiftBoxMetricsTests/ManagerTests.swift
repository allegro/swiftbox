import Foundation
import XCTest

@testable import NIO
@testable import SwiftBoxMetrics

class MetricsManagerTests: XCTestCase {

    func testBootstrapFunctionShouldChangeHandler() throws {
        Metrics.bootstrap(FakeHandler())
        XCTAssert(Metrics.global is FakeHandler)
    }

    static var allTests: [(String, (MetricsManagerTests) -> () throws -> Void)] {
        return [
            ("testBootstrapFunctionShouldChangeHandler", testBootstrapFunctionShouldChangeHandler),
        ]
    }
}