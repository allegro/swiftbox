import Foundation

struct EnvParseError: Error {
    let message: String
}

let NULL_KEYWORD = "null"

/// Parser that allows to read simple key:value Dictionary<String, Any?> to nested structure using dicts, arrays and simple types
/// Separator is used to split keys into parts.
/// Each part corresponds to one level in output data.
///
/// If currentPart is last part, the value from input dict is assigned to it
/// If currentPart isn't last part and may be casted to int, it means that it is array index (If there are indexes missing in result it will be filled with nil)
/// If currentPart isn't last part and isn't castable to int, it means that this is nested dictionary key
class FlatDictConfigParser {
    let data: [String: Any?]
    let separator: Character

    init(data: [String: Any?], separator: Character) {
        self.data = data
        self.separator = separator
    }

    /// Splits key to array of strings using predefined separator
    private func keyToPathArray(_ key: String) -> [String] {
        return key.split(separator: separator).compactMap { $0.lowercased() }
    }

    /// Joins array of string to KeyPathReferenceable format
    private func pathArrayToKeyPath(_ pathArray: [String]) -> String {
        return pathArray.joined(separator: ".")
    }

    public func decode() throws -> Storage {
        var result: Storage = [:]

        let sortedKeys = Array(data.keys).sorted()

        for key in sortedKeys {
            let value = data[key]
            let splittedPath = keyToPathArray(key)

            var path: [String] = []
            for (i, pathPart) in keyToPathArray(key).enumerated() {
                path.append("\(pathPart)")

                let keyPath = pathArrayToKeyPath(path)
                let isLastPart = i == splittedPath.count - 1
                let isCurrentKeyInt: Bool = Int("\(pathPart)") != nil
                let isNextKeyInt: Bool = isLastPart ? false : Int("\(splittedPath[i + 1])") != nil
                let currentValue: Any? = result[keyPath: keyPath]

                // Check if value exists
                if let currentValue = currentValue {
                    // Value already exists, need to check if type matches value
                    if isLastPart {
                        // Means that there is duplicate key in environment
                        throw EnvParseError(message: "Attempt to override existing value: '\(currentValue)' for path: '\(keyPath)', with '\(key)=\(String(describing: value))'. Please check env configuration")
                    } else {
                        if currentValue as? Storage != nil, !isNextKeyInt {
                            // Current value is dict and next key is string type
                            continue
                        } else if currentValue as? StorageArray != nil, isNextKeyInt {
                            // Current value is array and next key is int type
                            continue
                        } else {
                            // Value is not wrapper type
                            throw EnvParseError(message: "Misconfiguration error: Expected array or dict, got '\(currentValue)' for path: '\(keyPath)', with '\(key)=\(String(describing: value))'. Please check env configuration")
                        }
                    }
                } else {
                    // If it's last part value should be assigned directly
                    // If not, need to create array or dict wrapper
                    if isCurrentKeyInt {
                        fillMissingArrayIndexes(path: path, pathPart: pathPart, result: &result)
                    }

                    if isLastPart {
                        if let value = (value as? String), value == NULL_KEYWORD {
                            result[keyPath: keyPath] = nil
                        } else {
                            result[keyPath: keyPath] = value as Any?
                        }
                    } else {
                        // Check whether next key might be casted to INT, if so we suppose that wrapper should be array
                        // If not dict is used as wrapper
                        if isNextKeyInt {
                            result[keyPath: keyPath] = []
                        } else {
                            result[keyPath: keyPath] = [:]
                        }
                    }
                }
            }
        }

        return result
    }

    private func fillMissingArrayIndexes(path: [String], pathPart: String, result: inout Storage) {
        let parentPath = pathArrayToKeyPath(Array(path[0 ..< path.count - 1]))
        var parentValue = result[keyPath: parentPath] as! [Any?]
        let currentIntKey = Int("\(pathPart)")!

        if parentValue.count <= currentIntKey {
            // Fill missing values with nil
            for _ in parentValue.count ... currentIntKey {
                parentValue.append(nil)
            }
            result[keyPath: parentPath] = parentValue
        }
    }
}
