actor KeyValueStore<Key: Hashable & Sendable, Value: Sendable> {
    private var storage: [Key: Value] = [:]

    init(initialValues: [Key: Value] = [:]) {
        self.storage = initialValues
    }

    func get(_ key: Key) -> Value? {
        storage[key]
    }

    @discardableResult
    func updateValue(_ value: Value, forKey key: Key) -> Value? {
        storage.updateValue(value, forKey: key)
    }

    @discardableResult
    func modify<R>(_ key: Key, _ body: @Sendable (inout Value?) throws -> R) rethrows -> R {
        var value = storage[key]
        let result = try body(&value)
        storage[key] = value
        return result
    }

    @discardableResult
    func updateValue(forKey key: Key, default defaultValue: @autoclosure () -> Value, _ transform: @Sendable (inout Value) -> Void) -> Value {
        if storage[key] == nil {
            storage[key] = defaultValue()
        }
        var current = storage[key]!
        transform(&current)
        storage[key] = current
        return current
    }

    @discardableResult
    func removeValue(forKey key: Key) -> Value? {
        storage.removeValue(forKey: key)
    }

    func removeAll(keepingCapacity keep: Bool = false) {
        storage.removeAll(keepingCapacity: keep)
    }

    var count: Int {
        storage.count
    }

    func contains(_ key: Key) -> Bool {
        storage[key] != nil
    }

    func values() -> [Value] {
        Array(storage.values)
    }

    func allItems() -> [(Key, Value)] {
        Array(storage)
    }

    func keys() -> [Key] {
        Array(storage.keys)
    }
}
