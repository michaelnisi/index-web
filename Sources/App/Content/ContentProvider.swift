import Foundation

struct ContentProvider: Sendable {
    struct Dependencies: Sendable {
        let posts: @Sendable () async throws -> [Post]
    }

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func posts() async throws -> [Post] {
        try await dependencies.posts()
    }
}
