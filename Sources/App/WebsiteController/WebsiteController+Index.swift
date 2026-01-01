import Foundation
import Hummingbird

extension WebsiteController {
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
                    let content = try await ContentProvider.file
                        .post(matching: post.path.inPartialsDirectory)

                    return IndexData.Post(
                        content: content,
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

        let data = IndexData(title: .title("Software Engineer"), posts: posts)

        guard let html = mustacheLibrary.render(data, withTemplate: "index") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }

        return HTML(html: html)
    }
}

private struct IndexData {
    struct Post: Comparable {
        let content: String
        let date: Date
        let title: String
        let url: String
        let link: String
    }

    let title: String
    let posts: [Post]
    let ld: String

    init(title: String, posts: [Post]) {
        self.title = title
        self.posts = posts
        ld = IndexLinkedData(title: title).json
    }
}

extension IndexData.Post {
    init(content: Content, link: String) {
        self.content = content.html
        date = content.date
        title = content.title
        url = content.absoluteURL
        self.link = link
    }

    fileprivate static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.date > rhs.date
    }
}
