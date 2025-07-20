import Foundation

struct ContentProvider: Sendable {
    struct Dependencies: Sendable {
        let partial: @Sendable (String) async throws -> HTMLPartial
    }

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func partial(matching path: String) async throws -> HTMLPartial {
        try await dependencies.partial(path)
    }
}
