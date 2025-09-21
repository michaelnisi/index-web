import Foundation
import Testing

@testable import App

struct FilenameTests {
    @Test func valid() throws {
        let strings = [
            "Partials/posts/2025-06-06-troubled.md",
            "2025-06-06-troubled.md",
        ]

        let expected = try Date("2025-06-06T00:00:00Z", strategy: .iso8601)

        for url in strings.map(URL.init(string:)) {
            #expect(url!.leadingISO8601DateFromFilename() == expected)
        }
    }

    @Test func invalid() throws {
        let strings = [
            "2025-06-06.md",
            "troubled-2025-06-06.md",
            "2025-13-06-troubled.md",
            "2025-06-32-troubled.md",
            "2025-06.md",
            "2025-06-troubled.md",
        ]

        for url in strings.map(URL.init(string:)) {
            #expect(url!.leadingISO8601DateFromFilename() == nil)
        }
    }
}
