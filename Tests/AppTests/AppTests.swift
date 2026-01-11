import HummingbirdTesting
import Logging
import Testing

@testable import App

struct AppTests {
    struct TestArguments: AppArguments {
        let hostname = "127.0.0.1"
        let port = 0
        let logLevel: Logger.Level
    }

    @Test func index() async throws {
        let args = TestArguments(logLevel: .trace)
        let app = try await buildApplication(args)

        try await app.test(.router) { client in
            try await client.execute(uri: "/", method: .get) { response in
                #expect(response.status == .ok)
            }
        }
    }
}
