import Foundation
import Hummingbird

extension WebsiteController {
    @Sendable func indexHandler(request: Request, context: some RequestContext) async throws -> HTML {
        if let cached = await cachedHTML(request: request) {
            return HTML(html: cached)
        }

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

        let data = IndexData(
            title: .title("Software Engineer"),
            canonical: .canonicalURL(for: request.uri.path),
            posts: posts
        )

        guard let html = mustacheLibrary.render(data, withTemplate: "index") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }

        await cacheHTML(request: request, html: html)

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
        let wordCount: Int
        let dateString: String
    }

    let title: String
    let canonical: String
    let description: String
    let posts: [Post]
    let ld: String

    init(title: String, canonical: String, posts: [Post]) {
        self.title = title
        self.canonical = canonical
        description = "Strong types and single fins. Bring back the personal web."
        self.posts = posts
        ld = IndexLinkedData(title: title).json
    }
}

extension IndexData.Post {
    init(content: Content, link: String) {
        self.content = content.html
        date = content.date
        title = content.title
        url = content.canonical
        self.link = link
        wordCount = content.wordCount
        dateString = .date(date: content.date)
    }

    fileprivate static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.date > rhs.date
    }
}
