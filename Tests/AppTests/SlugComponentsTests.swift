import Testing

@testable import App

struct SlugComponentsTests {
    typealias SUT = SlugComponents

    @Test func string() {
        #expect(SUT(string: "hello") == nil)
        #expect(SUT(string: "posts/2025/01/31/hello") == SUT(year: 2025, month: 1, day: 31, slug: "hello"))
        #expect(SUT(string: "posts/2025/04/02/hello") == SUT(year: 2025, month: 4, day: 2, slug: "hello"))
    }
}
