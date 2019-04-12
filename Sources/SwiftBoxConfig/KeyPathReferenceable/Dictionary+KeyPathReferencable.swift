extension Dictionary: KeyPathReferenceable {
    public subscript(keyPath keyPath: String) -> Any? {
        get {
            guard let keyPath = Dictionary.keyPathKeys(forKeyPath: keyPath) else { return nil }
            return getValue(forKeyPath: keyPath)
        }
        set {
            guard let keyPath = Dictionary.keyPathKeys(forKeyPath: keyPath) else { return }
            setValue(newValue, forKeyPath: keyPath)
        }
    }

    private static func keyPathKeys(forKeyPath: String) -> [String]? {
        let keys = forKeyPath.components(separatedBy: ".").reversed().compactMap { $0 }
        return keys.isEmpty ? nil : keys
    }

    public func getValue(forKeyPath keyPath: [String]) -> Any? {
        let val: Value? = self[keyPath.last! as! Key]

        guard let unwrapped = self.conditionallyUnwrapDoubleOptional(val) else {
            return nil
        }

        if keyPath.count == 1 {
            // If this is last part of key return value
            // For example:
            //   dict.subdict.leaf
            //   Last element is `leaf`
            return unwrapped
        } else if unwrapped as? [String: Any?] != nil {
            return (unwrapped as! [String: Any?]).getValue(forKeyPath: Array(keyPath.dropLast()))
        } else if unwrapped as? [Any?] != nil {
            return (unwrapped as! [Any?]).getValue(forKeyPath: Array(keyPath.dropLast()))
        } else {
            fatalError("Unexpected")
        }
    }

    private func conditionallyUnwrapDoubleOptional(_ value: Any?) -> Any? {
        guard let value = value else {
            return nil
        }

        if case Optional<Any>.some(let inner) = (value as Any) {
            return inner as! Value
        } else if case Optional<Any>.none = (value as Any) {
            return nil
        }
        return value
    }

    public mutating func setValue(_ value: Any?, forKeyPath keyPath: [String]) {
        let currentValue = self[keyPath.last! as! Key]

        if keyPath.count == 1 {
            _ = (value as? Value).map { self.updateValue($0, forKey: keyPath.last! as! Key) }
        } else if var subDict = currentValue as? [String: Any?] {
            subDict.setValue(value, forKeyPath: Array(keyPath.dropLast()))
            self[keyPath.last! as! Key] = (subDict as! Value)
        } else if var subArray = currentValue as? [Any?] {
            subArray.setValue(value, forKeyPath: Array(keyPath.dropLast()))
            self[keyPath.last! as! Key] = (subArray as! Value)
        } else {
            fatalError("Unknown state")
        }
    }
}
