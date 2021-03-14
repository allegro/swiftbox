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
        log(message, level: .debug)
    }

    public func error(_ message: String) {
        log(message, level: .error)
    }

    public func warning(_ message: String) {
        log(message, level: .warning)
    }

    public func trace(_ message: String) {
        log(message, level: .trace)
    }

    public func info(_ message: String) {
        log(message, level: .info)
    }

    public func critical(_ message: String) {
        log(message, level: .critical)
    }

    public func notice(_ message: String) {
        log(message, level: .notice)
    }

    private func log(_ message: String, level: Logger.Level) {
        print("[\(level.rawValue.uppercased())] \(dateFormatter.string(from: Date())) \(message)")
    }
}
