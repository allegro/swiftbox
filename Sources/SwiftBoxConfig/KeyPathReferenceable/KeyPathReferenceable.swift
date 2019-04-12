/// Protocol that extends Dictionary and Array behaviour and allows to get and set values using string keypaths
/// Example: dict[keyPath: "some.nested.array.5.test"]
/// Update keeps reference to updated object
internal protocol KeyPathReferenceable {
    subscript(keyPath _: String) -> Any? { get set }
    func getValue(forKeyPath keyPath: [String]) -> Any?
    mutating func setValue(_ value: Any?, forKeyPath keyPath: [String])
}
