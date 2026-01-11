import Foundation
import Hummingbird

extension WebsiteController {
    @Sendable func aboutHandler(request: Request, context: some RequestContext) async throws -> HTML {
        if let cached = await cachedHTML(request: request) {
            return HTML(html: cached)
        }

        guard let (_, path) = markdownTree.findWithPath(path: "Partials/about.md") else {
            throw HTTPError(.notFound)
        }

        let content = try await ContentProvider.file.page(matching: path)
        let data = AboutData(
            title: .title("About"),
            canonical: .canonicalURL(for: request.uri.path),
            post: content.html,
            description: content.description,
            wordCount: content.wordCount
        )

        guard let html = mustacheLibrary.render(data, withTemplate: "article") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }

        await cacheHTML(request: request, html: html)

        return HTML(html: html)
    }
}

private struct AboutData {
    let title: String
    let post: String
    let canonical: String
    let description: String
    let wordCount: Int
    let ld: String

    init(title: String, canonical: String, post: String, description: String, wordCount: Int) {
        self.title = title
        self.post = post
        self.canonical = canonical
        self.description = description
        self.wordCount = wordCount
        ld =
            AboutLinkedData(
                name: title,
                description: description,
                wordCount: wordCount
            )
            .json
    }
}
