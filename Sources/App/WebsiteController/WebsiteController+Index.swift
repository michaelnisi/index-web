import Hummingbird

extension WebsiteController {
    struct IndexData {
        struct Post {
            let title: String
        }

        let posts: [Post]
    }

    @Sendable func indexHandler(request: Request, context: some RequestContext) async throws -> HTML {
        let results: [String] = try await withThrowingTaskGroup(of: String.self) { group in
            guard let posts = markdownTree
                .allNodes(matching: "posts")
                .first?.node.allFiles() else {
                return []
            }

            for post in posts {
                group.addTask {
                    try await ContentProvider.file
                        .partial(matching: .partialsPath(post.path))
                        .html
                }
            }
            
            var collected: [String] = []

            for try await result in group {
                collected.append(result)
            }

            return collected
        }

        let posts = results.map(IndexData.Post.init(title:))
        let data = IndexData(posts: posts)

        guard let html = mustacheLibrary.render(data, withTemplate: "index") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }

        return HTML(html: html)
    }
}
