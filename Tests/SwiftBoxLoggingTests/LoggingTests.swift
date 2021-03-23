import Logging
import XCTest

@testable import SwiftBoxLogging

class Logger2Tests: XCTestCase {
    func testTimeShouldBeFormattedToISO8601() throws {
        let date = Date(timeIntervalSinceReferenceDate: 0)
        let event = ElasticsearchPayload(message: "Test", logger: "samplelogger", level: "test", file: "file", line: 1, function: "function", time: date)
        XCTAssertEqual(event.time, "2001-01-01T00:00:00.000Z")
    }

    func testLogger2EventShouldDumpToJson() throws {
        let date = Date(timeIntervalSinceReferenceDate: 0)
        let event = ElasticsearchPayload(message: "Test", logger: "samplelogger", level: "test", file: "file", line: 1, function: "function", time: date)

        let serializedEvent = try JSONDecoder().decode(ElasticsearchPayload.self, from: event.toJSON().data(using: .utf8)!)

        XCTAssertEqual(event, serializedEvent)
    }

    func testLoggerShouldPrintOnConsole() throws {
        let loggerLabel = "testLogger"
        let loggerMessage = "message from logger"

        var output: String = ""
        let logger = ElasticsearchLogHandler(label: loggerLabel, printFunction: { text in output = text })

        logger.log(
            level: .debug,
            message: Logger.Message(stringLiteral: loggerMessage),
            metadata: nil,
            source: "",
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertNotNil(output)
        let logEvent = try JSONDecoder().decode(ElasticsearchPayload.self, from: output.data(using: .utf8)!)
        XCTAssertEqual(logEvent.message, loggerMessage)
        XCTAssertEqual(logEvent.logger, loggerLabel)
    }

    static var allTests: [(String, (Logger2Tests) -> () throws -> Void)] {
        return [
            ("testTimeShouldBeFormattedToISO8601", testTimeShouldBeFormattedToISO8601),
            ("testLogger2EventShouldDumpToJson", testLogger2EventShouldDumpToJson),
            ("testLoggerShouldPrintOnConsole", testLoggerShouldPrintOnConsole)
        ]
    }
}
