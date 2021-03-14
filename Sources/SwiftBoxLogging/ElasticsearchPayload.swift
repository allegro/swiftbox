import Foundation

struct ElasticsearchPayload: Codable {
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

extension ElasticsearchPayload: Equatable {}

fileprivate let logTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
    return formatter
}()
