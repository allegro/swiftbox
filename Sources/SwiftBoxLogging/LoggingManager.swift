import Logging

public enum Logging {
    private static var factory: (String) -> Logger = { _ in
        PrintLogger()
    }

    public static func bootstrap(_ factory: @escaping (String) -> Logger) {
        self.factory = factory
    }

    public static func make(_ label: String) -> Logger {
        return factory(label)
    }
}
