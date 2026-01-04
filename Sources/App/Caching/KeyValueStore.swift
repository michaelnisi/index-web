import Foundation

actor KeyValueStore<Key: Hashable, Value> {
    private var storage: [Key: Value] = [:]

    init(initialValues: [Key: Value] = [:]) {
        self.storage = initialValues
    }

    func get(_ key: Key) -> Value? {
        storage[key]
    }

    func set(_ key: Key, value: Value) {
        storage[key] = value
    }

    func remove(_ key: Key) {
        storage.removeValue(forKey: key)
    }

    func removeAll(keepingCapacity keep: Bool = false) {
        storage.removeAll(keepingCapacity: keep)
    }

    var count: Int {
        storage.count
    }

    func keys() -> [Key] {
        Array(storage.keys)
    }
}
