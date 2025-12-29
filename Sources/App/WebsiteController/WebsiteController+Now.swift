import Foundation
import Hummingbird

extension WebsiteController {
    @Sendable func nowHandler(request: Request, context: some RequestContext) async throws -> HTML {
        guard let (_, path) = markdownTree.findWithPath(path: "Partials/now.md") else {
            throw HTTPError(.notFound)
        }

        let html = try await ContentProvider.file.page(matching: path).html
        let data = NowData(title: "Michael Nisi — Now", post: html)

        guard let html = mustacheLibrary.render(data, withTemplate: "article") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }

        return HTML(html: html)
    }
}

private struct NowData {
    let title: String
    let post: String
    let ld: String

    init(title: String, post: String) {
        self.title = title
        self.post = post

        ld = """
            {
                "@context": "https://schema.org",
                "@type": "ProfilePage",
                "@id": "https://michaelnisi.com/now#webpage",
                "url": "https://michaelnisi.com/now",
                "name": "\(title)",
                "inLanguage": "en",
                "isPartOf": { "@id": "https://michaelnisi.com#website" },
                "mainEntity": { "@id": "https://michaelnisi.com#person" }
            }  
            """
    }
}
