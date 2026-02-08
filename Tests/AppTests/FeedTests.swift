import HTTPTypes
import HummingbirdTesting
import Logging
import Testing

@testable import App

@Suite("Feed Endpoints")
struct FeedTests {
    struct TestArguments: AppArguments {
        let hostname = "127.0.0.1"
        let port = 0
        let logLevel: Logger.Level = .warning
    }

    // MARK: - JSON Feed

    @Test("GET /feed.json returns 200 with JSON content type")
    func jsonFeedReturns200() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            try await client.execute(uri: "/feed.json", method: .get) { response in
                #expect(response.status == .ok)
                let contentType = response.headers[.contentType]
                #expect(contentType?.contains("application/feed+json") == true)
            }
        }
    }

    @Test("GET /feed.json returns valid JSON with feed version")
    func jsonFeedIsValidJSON() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            try await client.execute(uri: "/feed.json", method: .get) { response in
                let body = String(buffer: response.body)
                #expect(body.contains("https://jsonfeed.org/version/1.1"))
            }
        }
    }

    @Test("GET /feed.json returns ETag")
    func jsonFeedHasETag() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            try await client.execute(uri: "/feed.json", method: .get) { response in
                #expect(response.headers[.eTag] != nil)
            }
        }
    }

    @Test("GET /feed.json with If-None-Match returns 304")
    func jsonFeedConditionalGet() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            var etag: String?
            try await client.execute(uri: "/feed.json", method: .get) { response in
                etag = response.headers[.eTag]
            }
            let tag = try #require(etag)

            var headers = HTTPFields()
            headers[.ifNoneMatch] = tag
            try await client.execute(uri: "/feed.json", method: .get, headers: headers) { response in
                #expect(response.status == .notModified)
            }
        }
    }

    @Test("GET /feed.json items do not contain h1 title")
    func jsonFeedItemsOmitH1() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            try await client.execute(uri: "/feed.json", method: .get) { response in
                let body = String(buffer: response.body)
                #expect(!body.contains("<h1>"))
            }
        }
    }

    // MARK: - RSS Feed

    @Test("GET /feed returns 200 with RSS content type")
    func rssFeedReturns200() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            try await client.execute(uri: "/feed", method: .get) { response in
                #expect(response.status == .ok)
                let contentType = response.headers[.contentType]
                #expect(contentType?.contains("application/rss+xml") == true)
            }
        }
    }

    @Test("GET /feed returns valid RSS XML")
    func rssFeedIsValidXML() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            try await client.execute(uri: "/feed", method: .get) { response in
                let body = String(buffer: response.body)
                #expect(body.contains("<?xml version=\"1.0\""))
                #expect(body.contains("<rss version=\"2.0\""))
            }
        }
    }

    @Test("GET /feed returns ETag")
    func rssFeedHasETag() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            try await client.execute(uri: "/feed", method: .get) { response in
                #expect(response.headers[.eTag] != nil)
            }
        }
    }

    @Test("GET /feed items do not contain h1 title")
    func rssFeedItemsOmitH1() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            try await client.execute(uri: "/feed", method: .get) { response in
                let body = String(buffer: response.body)
                #expect(!body.contains("<h1>"))
            }
        }
    }

    @Test("GET /feed with If-None-Match returns 304")
    func rssFeedConditionalGet() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            var etag: String?
            try await client.execute(uri: "/feed", method: .get) { response in
                etag = response.headers[.eTag]
            }
            let tag = try #require(etag)

            var headers = HTTPFields()
            headers[.ifNoneMatch] = tag
            try await client.execute(uri: "/feed", method: .get, headers: headers) { response in
                #expect(response.status == .notModified)
            }
        }
    }
}
