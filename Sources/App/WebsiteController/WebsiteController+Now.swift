import Foundation
import Hummingbird

extension WebsiteController {
    @Sendable func nowHandler(request: Request, context: some RequestContext) async throws -> HTML {
        if let cached = await cachedHTML(request: request) {
            return HTML(html: cached)
        }

        guard let (_, path) = markdownTree.findWithPath(path: "Partials/now.md") else {
            throw HTTPError(.notFound)
        }

        let content = try await ContentProvider.file.page(matching: path)
        let data = NowData(
            title: .title("Now"),
            canonical: .canonicalURL(for: request.uri.path),
            post: content.html,
            description: content.description
        )

        guard let html = mustacheLibrary.render(data, withTemplate: "info") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }

        await cacheHTML(request: request, html: html)

        return HTML(html: html)
    }
}

private struct NowData {
    let title: String
    let post: String
    let canonical: String
    let description: String
    let ogType: String

    init(title: String, canonical: String, post: String, description: String) {
        self.title = title
        self.post = post
        self.canonical = canonical
        self.description = description
        ogType = "website"
    }
}
