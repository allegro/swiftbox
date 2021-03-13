import Logging
import Vapor

public enum Logging {
    private static var factory: (String) -> LoggerProtocol = { _ in
        PrintLogger()
    }

    public static func bootstrap(_ factory: @escaping (String) -> LoggerProtocol) {
        self.factory = factory
    }

    public static func make(_ label: String) -> LoggerProtocol {
        return factory(label)
    }
}
