import Logging

public typealias PrintHandler = (String) -> Void

public protocol LoggerProtocol {
    func debug(_ message: String)
    func error(_ message: String)
    func warning(_ message: String)
}

public class PrintLogger: LoggerProtocol {
    public func debug(_ message: String) {
        // fatalError("debug")
    }

    public func error(_ message: String) {
        // fatalError("error")
    }

    public func warning(_ message: String) {
        // fatalError("warning")
    }
}

