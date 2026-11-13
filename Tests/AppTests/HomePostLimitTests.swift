import Foundation
import HummingbirdTesting
import Logging
import Testing

@testable import App

@Suite("Home page post limit")
struct HomePostLimitTests {
    struct TestArguments: AppArguments {
        let hostname = "127.0.0.1"
        let port = 0
        let logLevel: Logger.Level = .warning
        let homePostLimit: Int
    }

    private let archiveLink = "Older posts in the archive"

    /// Returns the number of articles on the page at `uri` and whether it links to older posts.
    private func inspect(uri: String, limit: Int) async throws -> (articles: Int, hasArchiveLink: Bool) {
        let app = try await buildApplication(TestArguments(homePostLimit: limit))

        return try await app.test(.router) { client in
            try await client.execute(uri: uri, method: .get) { response in
                #expect(response.status == .ok)

                let html = String(buffer: response.body)

                return (
                    html.components(separatedBy: "<article>").count - 1,
                    html.contains(archiveLink)
                )
            }
        }
    }

    private func totalPosts() async throws -> Int {
        try await inspect(uri: "/archive", limit: defaultHomePostLimit).articles
    }

    @Test func fewerPostsThanLimit() async throws {
        let total = try await totalPosts()
        let result = try await inspect(uri: "/", limit: total + 1)

        #expect(result.articles == total)
        #expect(!result.hasArchiveLink)
    }

    @Test func exactlyAsManyPostsAsLimit() async throws {
        let total = try await totalPosts()
        let result = try await inspect(uri: "/", limit: total)

        #expect(result.articles == total)
        #expect(!result.hasArchiveLink)
    }

    @Test func morePostsThanLimit() async throws {
        let total = try await totalPosts()
        #expect(total > 3)

        let result = try await inspect(uri: "/", limit: 3)

        #expect(result.articles == 3)
        #expect(result.hasArchiveLink)
    }

    @Test func archiveIgnoresLimit() async throws {
        let total = try await totalPosts()
        let result = try await inspect(uri: "/archive", limit: 1)

        #expect(result.articles == total)
    }
}
