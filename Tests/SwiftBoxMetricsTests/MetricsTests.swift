import Foundation
import NIO
import XCTest

@testable import SwiftBoxMetrics

class TimeAmountTests: XCTestCase {

    func testTimeAmountShouldConvertTimeProperly() throws {
        let timeAmount = TimeAmount.milliseconds(1500)
        XCTAssertEqual(Double(timeAmount.nanoseconds), 1.5 * 1_000_000_000)
        XCTAssertEqual(timeAmount.toMicroseconds(), 1.5 * 1_000_000)
        XCTAssertEqual(timeAmount.toMilliseconds(), 1.5 * 1_000)
        XCTAssertEqual(timeAmount.toSeconds(), 1.5)
    }

    static var allTests: [(String, (TimeAmountTests) -> () throws -> Void)] {
        return [
            ("testTimeAmountShouldConvertTimeProperly", testTimeAmountShouldConvertTimeProperly),
        ]
    }
}

