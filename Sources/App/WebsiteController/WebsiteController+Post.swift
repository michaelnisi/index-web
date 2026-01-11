import Foundation
import Hummingbird

extension WebsiteController {
    @Sendable func postHandler(request: Request, context: some RequestContext) async throws -> HTML {
        if let cached = await cachedHTML(request: request) {
            return HTML(html: cached)
        }

        guard let (_, path) = markdownTree.findWithPath(path: request.uri.path.markdownPath().inPartialsDirectory) else {
            throw HTTPError(.notFound)
        }

        let content = try await ContentProvider.file.post(matching: path)
        let data = PostData(
            title: .title(content.title),
            canonical: .canonicalURL(for: request.uri.path),
            content: content
        )

        guard let html = mustacheLibrary.render(data, withTemplate: "article") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }

        await cacheHTML(request: request, html: html)

        return HTML(html: html)
    }
}

private struct PostData {
    let title: String
    let post: String
    let canonical: String
    let description: String
    let wordCount: Int
    let dateString: String
    let ld: String

    init(title: String, canonical: String, content: Content) {
        self.title = title
        self.post = content.html
        self.canonical = canonical
        wordCount = content.wordCount
        dateString = .date(date: content.date)
        description = content.description
        ld =
            PostLinkedData(
                canonical: canonical,
                name: content.title,
                description: content.description,
                wordCount: content.wordCount
            ).json
    }
}
