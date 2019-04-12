extension Array: KeyPathReferenceable {
    public subscript(keyPath keyPath: String) -> Any? {
        get {
            guard let keyPath = Array.keyPathKeys(forKeyPath: keyPath)
                    else { return nil }
            return getValue(forKeyPath: keyPath)
        }
        set {
            guard let keyPath = Array.keyPathKeys(forKeyPath: keyPath),
                  let newValue = newValue else { return }
            setValue(newValue, forKeyPath: keyPath)
        }
    }

    private static func keyPathKeys(forKeyPath: String) -> [String]? {
        let keys = forKeyPath.components(separatedBy: ".").reversed().compactMap { $0 }
        return keys.isEmpty ? nil : keys
    }

    public func getValue(forKeyPath keyPath: [String]) -> Any? {
        guard let key = Int(keyPath.last!) else {
            fatalError("Wrong key")
        }
        if key >= count {
            return nil
        }
        let value = self[key]

        guard let unwrapped = self.conditionallyUnwrapDoubleOptional(value) else {
            return nil
        }

        if keyPath.count == 1 {
            // If this is last part of key return value
            // For example:
            //   array.0.subarray.0.leaf
            //   Last element is `leaf`
            return unwrapped
        } else if unwrapped as? [String: Any] != nil {
            return (unwrapped as! [String: Any]).getValue(forKeyPath: [String](keyPath.dropLast()))
        } else if unwrapped as? [Any] != nil {
            return (unwrapped as! [Any]).getValue(forKeyPath: [String](keyPath.dropLast()))
        } else {
            return unwrapped
        }
    }

    private func conditionallyUnwrapDoubleOptional(_ value: Any) -> Any? {
        if case Optional<Any>.some(let inner) = (value as Any) {
            return inner as! Element
        } else if case Optional<Any>.none = (value as Any) {
            return nil
        }
        return value
    }

    public mutating func setValue(_ value: Any?, forKeyPath keyPath: [String]) {
        guard let key = Int(keyPath.last!) else {
            fatalError("Wrong key")
        }

        let currentValue = self[key]

        if keyPath.count == 1 {
            _ = (value as? Element).map { self[key] = $0 }
        } else if var subDict = currentValue as? [String: Any?] {
            subDict.setValue(value, forKeyPath: [String](keyPath.dropLast()))
            self[key] = subDict as! Element
        } else if var subArray = currentValue as? [Any?] {
            subArray.setValue(value, forKeyPath: [String](keyPath.dropLast()))
            self[key] = subArray as! Element
        } else {
            fatalError("Unknown state")
        }
    }
}
