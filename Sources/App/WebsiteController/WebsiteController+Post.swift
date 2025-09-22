import Hummingbird

extension WebsiteController {
    @Sendable func postHandler(request: Request, context: some RequestContext) async throws -> HTML {
        guard let (_, path) = markdownTree.findWithPath(path: .partialsPath(request.uri.path.markdownPath())) else {
            throw HTTPError(.notFound)
        }

        let html = try await ContentProvider.file.partial(matching: path).html
        let data = ["post": html]

        guard let html = mustacheLibrary.render(data, withTemplate: "article") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }

        return HTML(html: html)
    }
}

extension String {
    static func partialsPath(_ path: String) -> String {
        "Partials/\(path)"
    }
}
