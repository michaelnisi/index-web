import Foundation
import Hummingbird

extension WebsiteController {
    struct IndexData {
        struct Post {
            let title: String
            let date: Date
        }

        let posts: [Post]
    }

    @Sendable func indexHandler(request: Request, context: some RequestContext) async throws -> HTML {
        let results: [HTMLPartial] = try await withThrowingTaskGroup(of: HTMLPartial.self) { group in
            guard
                let posts =
                    markdownTree
                    .allNodes(matching: "posts")
                    .first?.node.allFiles()
            else {
                return []
            }

            for post in posts {
                group.addTask {
                    try await ContentProvider.file
                        .partial(matching: .partialsPath(post.path))
                }
            }

            var collected: [HTMLPartial] = []

            for try await result in group {
                collected.append(result)
            }

            return collected
        }

        let posts =
            results
            .map {
                return IndexData.Post(title: $0.html, date: $0.date)
            }
            .sorted {
                $0.date > $1.date
            }

        let data = IndexData(posts: posts)

        guard let html = mustacheLibrary.render(data, withTemplate: "index") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }

        return HTML(html: html)
    }
}
