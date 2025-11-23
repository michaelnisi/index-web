import Foundation
import Hummingbird

extension WebsiteController {
    struct IndexData {
        struct Post {
            let content: String
            let date: Date
            let link: String
        }

        let posts: [Post]
    }

    @Sendable func indexHandler(request: Request, context: some RequestContext) async throws -> HTML {
        let posts: [IndexData.Post] = try await withThrowingTaskGroup(of: IndexData.Post.self) { group in
            guard
                let posts = markdownTree.allNodes(matching: "posts")
                    .first?.node.allFiles()
            else {
                return []
            }

            for post in posts {
                group.addTask {
                    let partial = try await ContentProvider.file
                        .post(matching: .partialsPath(post.path))

                    return IndexData.Post(
                        content: partial.html,
                        date: partial.date,
                        link: post.path.toDirectoryPath()
                    )
                }
            }

            var acc: [IndexData.Post] = []

            for try await result in group {
                acc.append(result)
            }

            return acc.sorted()
        }

        let data = IndexData(posts: posts)

        guard let html = mustacheLibrary.render(data, withTemplate: "index") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }

        return HTML(html: html)
    }
}

extension WebsiteController.IndexData.Post: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.date > rhs.date
    }
}
