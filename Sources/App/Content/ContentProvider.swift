import Foundation

struct ContentProvider: Sendable {
    struct Dependencies: Sendable {
        let post: @Sendable (String) async throws -> HTMLPartial
        let page: @Sendable (String) async throws -> HTMLPartial
    }

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func post(matching path: String) async throws -> HTMLPartial {
        try await dependencies.post(path)
    }

    func page(matching path: String) async throws -> HTMLPartial {
        try await dependencies.page(path)
    }
}
