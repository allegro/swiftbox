import Core
import Foundation

import SwiftBoxLogging

private var logger = Logging.make(#file)

public enum DecoderError: Error {
    case castError(String)
    case invalidKey(String)
    case invalidIndexing(String)
}

private func toStringKeyPath(_ codingPath: [CodingKey]) -> String {
    return codingPath.map { key in
        return key.intValue != nil ? String(key.intValue!) : key.stringValue
    }.joined(separator: ".")
}

public typealias Storage = [String: Any?]
public typealias StorageArray = [Any?]

/// Dictionary decoder that is responsible for decoding merged output from ConfigSource into type-safe Configuration structure.
/// Custom types may be decoded as well, just conform to decodable protocol.
public struct DictionaryDecoder: Decoder {
    public var codingPath: [CodingKey]
    public var userInfo: [CodingUserInfoKey: Any] {
        return [:]
    }

    public let storage: Storage

    init(codingPath: [CodingKey], storage: Storage) {
        self.codingPath = codingPath
        self.storage = storage
    }

    public func container<Key>(keyedBy _: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        return KeyedDecodingContainer(DictionaryKeyedDecoder<Key>(codingPath: codingPath, storage: storage))
    }

    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return DictionaryUnkeyedDecoder(codingPath: codingPath, storage: storage)
    }

    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return DictionarySingleValueDecoder(codingPath: codingPath, storage: storage)
    }
}

private struct DictionarySingleValueDecoder: SingleValueDecodingContainer {
    var codingPath: [CodingKey]
    let storage: Storage

    init(codingPath: [CodingKey], storage: Storage) {
        self.codingPath = codingPath
        self.storage = storage
    }

    public func decodeNil() -> Bool {
        let keyPath = toStringKeyPath(codingPath)
        guard let value = self.storage[keyPath: keyPath] else {
            return true
        }
        if case Optional<Any>.none = value {
            return true
        }
        return false
    }

    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        let keyPath = toStringKeyPath(codingPath)
        let value = storage[keyPath: keyPath]

        do {
            return try unbox(value: value, to: type)
        } catch let error as DecoderError {
            logger.error("Error when decoding \(keyPath): \(error)")
            throw error
        }
    }

    private func unbox<To>(value: Any?, to: To.Type) throws -> To {
        guard let value = value else {
            throw DecoderError.castError("Cannot cast nil to \(to)")
        }

        if to.self is Bool.Type, let value = value as? Bool {
            return value as! To
        } else if to.self is String.Type, let value = value as? String {
            return value as! To
        } else if to.self is Int.Type, let value = value as? Int {
            return value as! To
        } else if to.self is Double.Type, let value = value as? Double {
            return value as! To
        } else if to.self is Float.Type, let value = value as? Float {
            return value as! To
        } else if let value = value as? String {
            return try unbox(value: value, to: to)
        } else {
            guard let castValue = value as? To else {
                throw DecoderError.castError("Cannot cast \(value) to \(to)")
            }

            return castValue
        }
    }

    private func unbox<To>(value: String, to: To.Type) throws -> To {
        if to.self is Bool.Type {
            return try unboxBool(value: value) as! To
        } else if to.self is Int.Type {
            return Int(value) as! To
        } else if to.self is Double.Type {
            return Double(value) as! To
        } else if to.self is Float.Type {
            return Float(value) as! To
        }

        guard let castValue = value as? To else {
            throw DecoderError.castError("Cannot cast \(value) to \(to)")
        }
        return castValue
    }

    private func unboxBool(value: String) throws -> Bool {
        let lowercased: String = value.lowercased()

        if ["1", "true"].contains(lowercased) {
            return true
        } else if ["0", "false"].contains(lowercased) {
            return false
        }

        throw DecoderError.castError("Unknown value \(value) for boolean type. Allowed values are: 1, true, 0, false")
    }
}

private struct DictionaryKeyedDecoder<K>: KeyedDecodingContainerProtocol where K: CodingKey {
    var codingPath: [CodingKey]
    var allKeys: [K]
    let storage: Storage

    init(codingPath: [CodingKey], storage: Storage) {
        self.codingPath = codingPath
        self.storage = storage

        let keyPath = toStringKeyPath(self.codingPath)

        var value: Any
        if codingPath.count > 0 {
            value = self.storage[keyPath: keyPath] ?? [:]
        } else {
            value = self.storage
        }

        let keys = (value as! [String: Any]).keys.map { value in
            // swiftformat:disable redundantInit
            return K.init(stringValue: value)
        }.filter {
            $0 != nil
        }
        allKeys = keys as! [K]
    }

    func contains(_ key: K) -> Bool {
        return allKeys.contains { $0.stringValue == key.stringValue }
    }

    func decodeNil(forKey key: K) throws -> Bool {
        let keyPath = toStringKeyPath(codingPath + [key])

        guard let value = self.storage[keyPath: keyPath] else {
            return true
        }
        if case Optional<Any>.none = value {
            return true
        }
        return false
    }

    func decode<T>(_: T.Type, forKey key: K) throws -> T where T: Decodable {
        let decoder = DictionaryDecoder(codingPath: codingPath + [key], storage: storage)
        return try T(from: decoder)
    }

    func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        return KeyedDecodingContainer(DictionaryKeyedDecoder<NestedKey>(codingPath: codingPath + [key], storage: storage))
    }

    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        return DictionaryUnkeyedDecoder(codingPath: codingPath + [key], storage: storage)
    }

    func superDecoder() throws -> Decoder {
        return DictionaryDecoder(codingPath: codingPath, storage: storage)
    }

    func superDecoder(forKey key: K) throws -> Decoder {
        return DictionaryDecoder(codingPath: codingPath + [key], storage: storage)
    }
}

private struct DictionaryUnkeyedDecoder: UnkeyedDecodingContainer {
    var codingPath: [CodingKey]
    var count: Int?
    var isAtEnd: Bool {
        return currentIndex >= count!
    }

    var currentIndex: Int
    var index: CodingKey {
        return BasicKey(currentIndex)
    }

    let storage: Storage

    init(codingPath: [CodingKey], storage: Storage) {
        self.codingPath = codingPath
        self.storage = storage
        currentIndex = 0

        let keyPath = toStringKeyPath(self.codingPath)
        if let value = self.storage[keyPath: keyPath] {
            count = (value as! [Any?]).count
        } else {
            count = 0
        }
    }

    mutating func decodeNil() throws -> Bool {
        let keyPath = toStringKeyPath(codingPath) + ".\(currentIndex)"
        let value = storage[keyPath: keyPath]

        if value == nil {
            currentIndex += 1
            return true
        } else {
            return false
        }
    }

    mutating func decode<T>(_: T.Type) throws -> T where T: Decodable {
        defer { currentIndex += 1 }
        let decoder = DictionaryDecoder(codingPath: codingPath + [index], storage: storage)
        return try T(from: decoder)
    }

    mutating func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        return KeyedDecodingContainer(DictionaryKeyedDecoder<NestedKey>(codingPath: codingPath + [index], storage: storage))
    }

    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        return DictionaryUnkeyedDecoder(codingPath: codingPath + [index], storage: storage)
    }

    mutating func superDecoder() throws -> Decoder {
        return DictionaryDecoder(codingPath: codingPath + [index], storage: storage)
    }
}
