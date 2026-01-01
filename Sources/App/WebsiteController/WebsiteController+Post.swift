import Foundation
import Hummingbird

extension WebsiteController {
    @Sendable func postHandler(request: Request, context: some RequestContext) async throws -> HTML {
        guard let (_, path) = markdownTree.findWithPath(path: request.uri.path.markdownPath().inPartialsDirectory) else {
            throw HTTPError(.notFound)
        }

        let content = try await ContentProvider.file.post(matching: path)
        let data = PostData(content: content)

        guard let html = mustacheLibrary.render(data, withTemplate: "article") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }

        return HTML(html: html)
    }
}

private struct PostData {
    let title: String
    let post: String
    let ld: String

    init(content: Content) {
        self.title = "Michael Nisi – \(content.title)"
        self.post = content.html
        ld =
            PostLinkedData(
                absoluteURL: content.absoluteURL,
                title: content.title,
                description: content.description,
                wordCount: content.wordCount
            ).json
    }
}
