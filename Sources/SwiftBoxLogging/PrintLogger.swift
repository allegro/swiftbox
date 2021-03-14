import Logging
import Foundation

public class PrintLogger: LoggerProtocol {
    public var level: Logger.Level
    public var showLocation: Bool
    public let dateFormatter: DateFormatter

    public init(level: Logger.Level = .info, showLocation: Bool = false, dateFormat: String = "yyyy-MM-dd HH:mm:ss ZZZZZ") {
        self.level = level
        self.showLocation = showLocation
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = dateFormat
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
