import Foundation

/// Config source protocol
/// Every config source used to bootstrap ConfigManager have to conform to this protocol.
public protocol ConfigSource {
    func getConfig() throws -> Storage
}

/// Environment configuration source
///
/// Allows reading configuration data from environment using following syntax:
///      struct Conf: Configuration {
///          let simple: String
///          let int: Int
///          let double: Double
///          let nested: NestedConf
///          let array: [String?]
///          let arraynested: [NestedConf]
///
///          struct NestedConf: Configuration {
///              let value: String?
///          }
///      }
///
///      For above example there should be following env variables specified:
///          - SIMPLE="test"
///          - INT="1"
///          - DOUBLE="1.0"
///          - NULL="null"
///          - NESTED_VALUE="test"
///          - ARRAY_0="test0"
///          - ARRAY_1="test1"
///          - ARRAY_2="null"
///          - ARRAYNESTED_0_VALUE="test0"
///          - ARRAYNESTED_1_VALUE="test1"
///          - ARRAYNESTED_2_VALUE="null"
public class EnvSource: ConfigSource {
    let prefix: String?
    let dataSource: [String: String]
    let separator: Character = "_"

    public init(dataSource: [String: String]? = nil, prefix: String? = nil) {
        self.dataSource = dataSource ?? ProcessInfo.processInfo.environment
        self.prefix = prefix
    }

    public func getConfig() throws -> Storage {
        let filteredData = filterByPrefix(data: dataSource, prefix: prefix)
        return try FlatDictConfigParser(data: filteredData, separator: separator).decode()
    }

    private func filterByPrefix(data: Storage, prefix: String?) -> Storage {
        if let prefix = prefix {
            let _prefix = prefix.lowercased() + String(separator)
            let filteredData = data.filter { key, _ in
                key.lowercased().starts(with: _prefix)
            }
            return Dictionary(
                    uniqueKeysWithValues: filteredData.map { key, value in
                        let newKey = key.lowercased().replacingOccurrences(of: _prefix, with: "")
                        return (newKey, value)
                    }
            )
        }

        return data
    }
}

/// JSON configuration source
/// Allows reading configuration from JSON data
public class JSONSource: ConfigSource {
    let dataSource: Data

    public init(dataSource: Data) {
        self.dataSource = dataSource
    }

    public func getConfig() throws -> Storage {
        let data = try JSONSerialization.jsonObject(with: dataSource, options: []) as! Storage
        return JSONNsNullMapper.mapNSNullToNil(data: data) as! Storage
    }
}

/// Recursively map NSNull to nil values due to Decodable requirements
private class JSONNsNullMapper {
    public class func mapNSNullToNil(data: Any?) -> Any? {
        if let data = data as? Storage {
            return mapDict(data: data)
        } else if let data = data as? StorageArray {
            return mapArray(data: data)
        } else {
            return mapSingle(data: data)
        }
    }

    private class func mapDict(data: Storage) -> Storage {
        var result: [String: Any?] = [:]
        for (key, value) in data {
            result[key] = mapNSNullToNil(data: value)
        }

        return result
    }

    private class func mapArray(data: StorageArray) -> StorageArray {
        var result: [Any?] = []
        for value in data {
            result.append(mapNSNullToNil(data: value))
        }

        return result
    }

    private class func mapSingle(data: Any?) -> Any? {
        if data is NSNull {
            return nil
        } else {
            return data
        }
    }
}

/// Dictionary configuration source
/// Allows reading configuration from Dictionary, may be used to specify in-code defaults for configuration
public class DictionarySource: ConfigSource {
    let dataSource: Storage

    public init(dataSource: Storage) {
        self.dataSource = dataSource
    }

    public func getConfig() throws -> Storage {
        return dataSource
    }
}

/// Command Line configuration source
///
/// Allows reading configuration data from environment using following syntax:
///      struct Conf: Configuration {
///          let simple: String
///          let int: Int
///          let double: Double
///          let null: String?
///          let nested: NestedConf
///          let array: [String?]
///          let arraynested: [NestedConf]
///
///          struct NestedConf: Configuration {
///              let value: String?
///          }
///      }
///
///      For above example there should be following env variables specified:
///          --config:simple=test
///          --config:int=1
///          --config:double=1.0
///          --config:null=null
///          --config:nested.value=test
///          --config:array.0=test0
///          --config:array.1=test1
///          --config:array.2=null
///          --config:arraynested.0.value=test0
///          --config:arraynested.1.value=test1
///          --config:arraynested.2.value=null
public class CommandLineSource: ConfigSource {
    public static let defaultPrefix = "--config:"
    let prefix: String?
    let commandLineArguments: [String]

    public init(dataSource: [String]? = nil, prefix: String? = defaultPrefix) {
        self.prefix = prefix
        commandLineArguments = dataSource ?? CommandLine.arguments
    }

    public func getConfig() throws -> Storage {
        let filteredData = filterRemovingPrefix(commandLineArguments)
        let inputStorage = mapArgumentsToStorage(filteredData)
        return try FlatDictConfigParser(data: inputStorage, separator: ".").decode()
    }

    /// Function used to filter passed config values
    /// It matches if given option starts with given prefix and either excludes them or includes (default behaviour, exclude=false)
    public static func filterArguments(_ arguments: [String], by prefix: String = defaultPrefix, exclude: Bool = false) -> [String] {
        return arguments.filter {
            $0.hasPrefix(prefix) == !exclude
        }
    }

    /// Filter input data by prefix and remove it
    private func filterRemovingPrefix(_ arguments: [String]) -> [String] {
        if let prefix = self.prefix {
            return CommandLineSource.filterArguments(arguments, by: prefix).map {
                $0.replacingOccurrences(of: prefix, with: "")
            }
        }
        return arguments
    }

    /// Split commands by "=" and map to Storage type
    private func mapArgumentsToStorage(_ arguments: [String]) -> Storage {
        return Dictionary(
                uniqueKeysWithValues: arguments.map { element in
                    let splitted = element.split(separator: "=", maxSplits: 1)
                    if splitted.count < 2 {
                        fatalError("Invalid commandline syntax config for \(element). Config variables should be in format: \(self.prefix ?? "--")server.port=8888")
                    }
                    return (String(splitted[0]), String(splitted[1...].joined(separator: "=")))
                }
        )
    }
}
