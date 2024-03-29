import Foundation
import Logging

public typealias PrintHandler = (String) -> Void

public class ElasticsearchLogHandler: LogHandler {
    let label: String
    let printFunction: PrintHandler

    public var metadata: Logger.Metadata = [:]
    public var logLevel: Logger.Level = .debug

    public init(
        label: String,
        printFunction: @escaping PrintHandler = { text in print(text) }
    ) {
        self.label = label
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

    // swiftlint:disable function_parameter_count
    public func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata _: Logger.Metadata?,
        source _: String,
        file: String,
        function: String,
        line: UInt
    ) {
        let payload = ElasticsearchPayload(
            message: message.description,
            logger: label,
            level: level.rawValue,
            file: file,
            line: line,
            function: function
        )

        printFunction(payload.toJSON())
        fflush(stdout)
    }
    // swiftlint:enable function_parameter_count
}
