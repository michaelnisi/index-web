import Testing

@testable import App

@Suite("KeyValueStore")
struct KeyValueStoreTests {
    @Test("init with initial values seeds storage")
    func initSeeds() async throws {
        let store = KeyValueStore<String, Int>(initialValues: ["a": 1, "b": 2])
        #expect(await store.count == 2)
        #expect(await store.get("a") == 1)
        #expect(await store.get("b") == 2)
    }

    @Test("updateValue returns previous and sets new")
    func updateReturnsPrevious() async throws {
        let store = KeyValueStore<String, Int>()
        let prevNil = await store.updateValue(1, forKey: "k")
        #expect(prevNil == nil)
        let prevOne = await store.updateValue(2, forKey: "k")
        #expect(prevOne == 1)
        #expect(await store.get("k") == 2)
    }

    @Test("removeValue returns removed")
    func removeReturnsRemoved() async throws {
        let store = KeyValueStore<String, Int>()
        #expect(await store.removeValue(forKey: "x") == nil)
        await store.updateValue(42, forKey: "x")
        #expect(await store.removeValue(forKey: "x") == 42)
        #expect(await store.get("x") == nil)
    }

    @Test("removeAll clears store")
    func removeAllClears() async throws {
        let store = KeyValueStore<String, Int>(initialValues: ["a": 1, "b": 2])
        await store.removeAll()
        #expect(await store.count == 0)
        #expect(!(await store.contains("a")))
        #expect(!(await store.contains("b")))
    }

    @Test("count and contains track presence")
    func countAndContains() async throws {
        let store = KeyValueStore<String, Int>()
        #expect(await store.count == 0)
        await store.updateValue(1, forKey: "a")
        #expect(await store.count == 1)
        #expect(await store.contains("a"))
        await store.updateValue(2, forKey: "b")
        #expect(await store.count == 2)
        await store.removeValue(forKey: "a")
        #expect(await store.count == 1)
        #expect(!(await store.contains("a")))
    }

    @Test("keys/values/items snapshots reflect current content")
    func snapshots() async throws {
        let store = KeyValueStore<String, Int>(initialValues: ["a": 1, "b": 2])
        let keys = await store.keys()
        let values = await store.values()
        let items = await store.allItems()
        #expect(Set(keys) == Set(["a", "b"]))
        #expect(Set(values) == Set([1, 2]))
        #expect(Set(items.map { $0.0 }) == Set(["a", "b"]))
        #expect(Set(items.map { $0.1 }) == Set([1, 2]))
    }

    @Test("snapshot independence from later mutations")
    func snapshotIndependence() async throws {
        let store = KeyValueStore<String, Int>(initialValues: ["a": 1])
        let keysBefore = await store.keys()
        let valuesBefore = await store.values()
        await store.updateValue(2, forKey: "b")
        // previous snapshots remain unchanged
        #expect(Set(keysBefore) == Set(["a"]))
        #expect(Set(valuesBefore) == Set([1]))
    }

    @Test("atomic modify throws: no change")
    func atomicModifyThrowsNoChange() async throws {
        enum Failure: Error { case boom }
        let store = KeyValueStore<String, Int>()
        await store.updateValue(1, forKey: "a")
        do {
            try await store.modify("a") { _ in
                throw Failure.boom
            }
            Issue.record("Expected to throw")
        } catch {
            #expect((error as? Failure) == .boom)
        }
        #expect(await store.get("a") == 1)
    }

    @Test("atomic modify insert and remove")
    func atomicModifyInsertRemove() async throws {
        let store = KeyValueStore<String, Int>()
        // insert
        await store.modify("a") { v in
            if v == nil { v = 1 }
        }
        #expect(await store.get("a") == 1)
        // remove
        await store.modify("a") { v in v = nil }
        #expect(await store.get("a") == nil)
    }

    @Test("atomic increment with updateValue(default:transform:)")
    func atomicIncrement() async throws {
        let store = KeyValueStore<String, Int>()
        let iterations = 500
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    await store.updateValue(forKey: "count", default: 0) { $0 += 1 }
                }
            }
        }
        #expect(await store.get("count") == iterations)
    }

    @Test("optional Value semantics: presence vs Optional.none")
    func optionalValueSemantics() async throws {
        let store = KeyValueStore<String, Int?>()
        // not present
        #expect(await store.contains("a") == false)
        #expect(await store.get("a") == nil)
        // present with .none
        let prev1 = await store.updateValue(nil, forKey: "a")
        #expect(prev1 == nil)  // no previous association
        #expect(await store.contains("a") == true)
        if let prev2 = await store.updateValue(1, forKey: "a") {
            // previous inner value should be nil
            #expect(prev2 == nil)
        } else {
            Issue.record("Expected previous outer to be .some")
        }
        // remove returns .some(nil) when previous value was nil
        let _ = await store.updateValue(nil, forKey: "a")
        if let removed = await store.removeValue(forKey: "a") {
            #expect(removed == nil)
        } else {
            Issue.record("Expected removed outer to be .some")
        }
    }

    @Test("updateValue(forKey:default:) does not override existing")
    func defaultNotOverriding() async throws {
        let store = KeyValueStore<String, Int>()
        await store.updateValue(10, forKey: "n")
        let result = await store.updateValue(forKey: "n", default: 999) { $0 += 5 }
        #expect(result == 15)
        #expect(await store.get("n") == 15)
    }

    @Test("modify returns closure result")
    func modifyReturnsResult() async throws {
        let store = KeyValueStore<String, Int>()
        let sum = await store.modify("a") { v -> Int in
            v = 3
            return 1 + 2
        }
        #expect(sum == 3)
        #expect(await store.get("a") == 3)
    }
}
