import Logging
import XCTest

@testable import SwiftBoxLogging


class Logger2Tests: XCTestCase {

    func testTimeShouldBeFormattedToISO8601() throws {
        let date = Date(timeIntervalSinceReferenceDate: 0)
        let event = Logger2Event(message: "Test", logger: "samplelogger", level: "test", file: "file", line: 1, function: "function", time: date)
        XCTAssertEqual(event.time, "2001-01-01T00:00:00.000Z")
    }

    func testLogger2EventShouldDumpToJson() throws {
        let date = Date(timeIntervalSinceReferenceDate: 0)
        let event = Logger2Event(message: "Test", logger: "samplelogger", level: "test", file: "file", line: 1, function: "function", time: date)

        let serializedEvent = try JSONDecoder().decode(Logger2Event.self, from: event.toJSON())

        XCTAssertEqual(event, serializedEvent)
    }

    func testLoggerShouldPrintOnConsole() throws {
        let loggerName = "testLogger"
        let loggerMessage = "message from logger"

        var output: String = ""
        let logger = Logger2(loggerName, printFunction: {text in output = text})

        logger.info(loggerMessage)
        XCTAssertNotNil(output)
        let logEvent = try JSONDecoder().decode(Logger2Event.self, from: output.data(using: .utf8)!)
        XCTAssertEqual(logEvent.message, loggerMessage)
        XCTAssertEqual(logEvent.logger, loggerName)
    }

    static var allTests: [(String, (Logger2Tests) -> () throws -> Void)] {
        return [
            ("testTimeShouldBeFormattedToISO8601", testTimeShouldBeFormattedToISO8601),
            ("testLogger2EventShouldDumpToJson", testLogger2EventShouldDumpToJson),
            ("testLoggerShouldPrintOnConsole", testLoggerShouldPrintOnConsole),
        ]
    }
}

class LoggingManagerTests: XCTestCase {

    func testLoggingManagerShouldReturnLogger() throws {
        let logger = Logging.make("test")
        XCTAssertNotNil(logger)
        logger.debug("test")
    }

    func testLoggingManagerBootstrapShouldOverrideDefaultHandler() throws {
        let loggerName = "root"

        Logging.bootstrap({ name in Logger2(name) })
        defer {
            Logging.bootstrap({ _ in PrintLogger() })
        }
        let logger = Logging.make(loggerName)

        XCTAssertNotNil(logger)
        logger.debug("test")
        XCTAssertEqual((logger as! Logger2).name, loggerName)
    }

    static var allTests: [(String, (LoggingManagerTests) -> () throws -> Void)] {
        return [
            ("testLoggingManagerShouldReturnLogger", testLoggingManagerShouldReturnLogger),
            ("testLoggingManagerBootstrapShouldOverrideDefaultHandler", testLoggingManagerBootstrapShouldOverrideDefaultHandler),
        ]
    }
}
