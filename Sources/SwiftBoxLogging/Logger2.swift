import Logging
import Vapor

public typealias PrintHandler = (String) -> Void

public final class Logger2: Logger {
    let name: String
    let printFunction: PrintHandler

    public init(_ name: String, printFunction: @escaping PrintHandler = { text in print(text) }) {
        self.name = name
        self.printFunction = printFunction
    }

    public func log(_ string: String, at level: LogLevel, file: String, function: String, line: UInt, column _: UInt) {
        let event = Logger2Event(
            message: string, logger: name, level: level.description, file: file, line: line, function: function
        )
        printFunction(event.toJSON())
        fflush(stdout)
    }
}

extension Logger2: ServiceType {
    public static var serviceSupports: [Any.Type] {
        return [Logger.self]
    }

    public static func makeService(for _: Container) throws -> Logger2 {
        return Logger2("root")
    }
}

struct Logger2Event: Codable {
    var message: String
    var logger: String
    var level: String
    var file: String
    var line: UInt
    var function: String
    var time: String

    enum CodingKeys: String, CodingKey {
        case time = "@timestamp"
        case message
        case logger
        case level
        case file
        case line
        case function
    }

    init(message: String, logger: String, level: String, file: String, line: UInt, function: String, time: Date = Date()) {
        self.message = message
        self.logger = logger
        self.level = level
        self.file = file
        self.line = line
        self.function = function
        self.time = logTimeFormatter.string(from: time)
    }

    func toJSON() -> String {
        let jsonData = try! JSONEncoder().encode(self)
        return String(bytes: jsonData, encoding: .utf8)!
    }
}

extension Logger2Event: Equatable {}

let logTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
    return formatter
}()
