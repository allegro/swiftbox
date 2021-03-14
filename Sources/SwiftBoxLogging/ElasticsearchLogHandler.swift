import Logging
import Foundation

public typealias PrintHandler = (String) -> Void

public class ElasticsearchLogHandler: LogHandler {
    let name: String
    let printFunction: PrintHandler

    public var metadata: Logger.Metadata = [:]
    public var logLevel: Logger.Level = .debug

    public init(
        _ name: String,
        printFunction: @escaping PrintHandler = { text in print(text) }
    ) {
        self.name = name
        self.printFunction = printFunction
    }

    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get {
            return metadata[key]
        }
        set {
            metadata[key] = newValue
        }
    }

    public func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        let payload = ElasticsearchPayload(
            message: message.description,
            logger: name,
            level: level.rawValue,
            file: file,
            line: line,
            function: function
        )

        printFunction(payload.toJSON())
        fflush(stdout)
    }
}