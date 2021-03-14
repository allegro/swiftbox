import Foundation
import Logging

public class PrintLogger: LoggerProtocol {
    public var level: Logger.Level
    public let dateFormatter: DateFormatter

    public init(
        level: Logger.Level = .info,
        dateFormat: String = "yyyy-MM-dd HH:mm:ss ZZZZZ"
    ) {
        self.level = level
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
    }

    public func debug(_ message: String) {
        log(message)
    }

    public func error(_ message: String) {
        log(message)
    }

    public func warning(_ message: String) {
        log(message)
    }

    private func log(_ message: String) {
        print("\(dateFormatter.string(from: Date())) \(message)")
    }
}
