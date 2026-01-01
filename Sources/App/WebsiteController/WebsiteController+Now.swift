import Foundation
import Hummingbird

extension WebsiteController {
    @Sendable func nowHandler(request: Request, context: some RequestContext) async throws -> HTML {
        guard let (_, path) = markdownTree.findWithPath(path: "Partials/now.md") else {
            throw HTTPError(.notFound)
        }

        let content = try await ContentProvider.file.page(matching: path)
        let data = NowData(title: "Michael Nisi — Now", post: content.html, description: content.description, wordCount: content.wordCount)

        guard let html = mustacheLibrary.render(data, withTemplate: "article") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }

        return HTML(html: html)
    }
}

private struct NowData {
    let title: String
    let post: String
    let description: String
    let wordCount: Int
    let ld: String

    init(title: String, post: String, description: String, wordCount: Int) {
        self.title = title
        self.post = post
        self.description = description
        self.wordCount = wordCount
        ld =
            NowLinkedData(
                name: title,
                description: description,
                wordCount: wordCount
            )
            .json
    }
}
