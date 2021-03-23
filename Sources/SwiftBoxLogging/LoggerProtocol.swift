public protocol LoggerProtocol {
    func trace(_ message: String)
    func info(_ message: String)
    func debug(_ message: String)
    func notice(_ message: String)
    func warning(_ message: String)
    func error(_ message: String)
    func critical(_ message: String)
}
