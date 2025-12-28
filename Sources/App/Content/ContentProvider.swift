import Foundation

struct ContentProvider: Sendable {
    struct Dependencies: Sendable {
        let post: @Sendable (String) async throws -> Content
        let page: @Sendable (String) async throws -> Content
    }

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func post(matching path: String) async throws -> Content {
        try await dependencies.post(path)
    }

    func page(matching path: String) async throws -> Content {
        try await dependencies.page(path)
    }
}
