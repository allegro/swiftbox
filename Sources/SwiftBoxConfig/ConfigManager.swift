import Foundation

import SwiftBoxLogging

private var logger = Logging.make(#file)

/// Config Manager protocol that Application Configuration Manager must conform to.
///
/// Example conformance:
/// public struct AppConfig: Configuration {
///     let host: String
/// }
///
/// extension AppConfig: ConfigManager {
///     public static var configuration: AppConfig? = nil
/// }
///
///
/// Types of config fields:
/// Every type used in config field must conform to Decodable protocol.
/// Fields may be optional:
///     let host: String?
///
/// Configs may be nested:
///     let conf: NestedConfig
/// NestedConfig must conform to decodable protocol
///
/// Configs may be include lists:
///     let hosts: [String]
///
///
/// On application startup bootstrap function must be called:
///     AppConfig.bootstrap(from: [EnvSource(), JSONSource(), DictionarySource()])
/// Multiple sources are supported, all source outputs will be merged into final data Dictionary
/// Nested dictionaries will be merged recursively, other types will be overridden.
///
/// After bootstrapping configuration may be accessed via AppConfig.global.
/// Custom sources may be created by conforming to ConfigSource protocol.
/// Custom types may be used in configuration, only requirement that this type must conform to Decodable protocol.
///
/// For more documentation about available sources see Sources file.
///
/// WARNING:
/// Config must be bootstrapped before accessing `global` config.)
/// Config cannot be bootstrapped more than once.
/// It will throw a fatalError if any of above occurs.
public protocol ConfigManager {
    associatedtype T: Configuration

    static var configuration: T? { get set }
    static var global: T { get }
    static func bootstrap(from sources: [ConfigSource]) throws
}

public typealias Configuration = Decodable

/// Extension with default implementations for Manager
extension ConfigManager {
    public static var global: T {
            return try! getConfiguration()
        }

    internal static func getConfiguration() throws -> T {
        guard let config = self.configuration else {
            throw ConfigManagerError.bootstrapRequired
        }
        return config
    }

    internal static func setConfiguration(value: T) throws {
        if configuration != nil {
            throw ConfigManagerError.alreadyBootstrapped
        }
        configuration = value
    }

    /// Bootstrap function used to read config from various sources.
    /// Merges all sources into one configuration.
    /// This function must be used before using `global` attribute and cannot be called more that once.
    public static func bootstrap(from sources: [ConfigSource]) throws {
        var result: Storage = [:]
        for source in sources {
            do {
                let sourceConfigData = try source.getConfig()
                result = mergeConfigs(result, sourceConfigData)
            } catch {
                logger.error("Error during parsing source: \(source), error: \(error)")
                throw error
            }
        }

        // swiftformat:disable redundantInit
        let config = try T.init(from: DictionaryDecoder(codingPath: [], storage: result))
        try setConfiguration(value: config)
    }

    /// Merge config Dictionaries recursively
    private static func mergeConfigs(_ config1: Storage, _ config2: Storage) -> Storage {
        var result = config1

        result.merge(config2) { current, new in
            if let currentDict = current as? Storage, let newDict = new as? Storage {
                return self.mergeConfigs(currentDict, newDict)
            }
            return new
        }

        return result
    }
}

public enum ConfigManagerError: Error {
    case bootstrapRequired
    case alreadyBootstrapped
}
