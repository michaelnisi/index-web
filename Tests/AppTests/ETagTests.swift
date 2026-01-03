import HTTPTypes
import HummingbirdTesting
import Logging
import NIOCore
import Testing

@testable import App

@Suite("ETag and Conditional Requests")
struct ETagTests {
    struct TestArguments: AppArguments {
        let hostname = "127.0.0.1"
        let port = 0
        let logLevel: Logger.Level = .warning
    }

    @Test("GET / returns 200 with weak ETag and Vary: Accept-Encoding")
    func getReturnsETag() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            try await client.execute(uri: "/", method: .get) { response in
                #expect(response.status == .ok)
                let etag = response.headers[.eTag]
                #expect(etag != nil)
                if let vary = response.headers[.vary] {
                    let parts = vary.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    #expect(parts.contains("Accept-Encoding"))
                } else {
                    Issue.record("Missing Vary header")
                }
            }
        }
    }

    @Test("GET / with If-None-Match returns 304 when ETag matches")
    func conditionalGetReturns304() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            // First request to capture ETag
            var etag: String?
            try await client.execute(uri: "/", method: .get) { response in
                etag = response.headers[.eTag]
                #expect(etag != nil)
            }
            let tag = try #require(etag)

            // Second request with If-None-Match
            var headers = HTTPFields()
            headers[.ifNoneMatch] = tag
            try await client.execute(uri: "/", method: .get, headers: headers) { response in
                #expect(response.status == .notModified)
                // 304 should not include a body; contentLength may be 0 or nil
                #expect(response.body.readableBytes == 0)
            }
        }
    }

    @Test("HEAD / returns headers (including ETag) and no body")
    func headReturnsHeadersNoBody() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            try await client.execute(uri: "/", method: .head) { response in
                #expect(response.status == .ok)
                #expect(response.headers[.eTag] != nil)
                #expect(response.body.readableBytes == 0)
            }
        }
    }
}
