import Foundation
import Hummingbird

extension WebsiteController {
    @Sendable func nowHandler(request: Request, context: some RequestContext) async throws -> HTML {
        guard let (_, path) = markdownTree.findWithPath(path: "Partials/now.md") else {
            throw HTTPError(.notFound)
        }

        let html = try await ContentProvider.file.page(matching: path).html
        let data = ["post": html]

        guard let html = mustacheLibrary.render(data, withTemplate: "article") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }

        return HTML(html: html)
    }
}
