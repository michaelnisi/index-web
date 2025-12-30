import Foundation
import Hummingbird

extension WebsiteController {
    @Sendable func aboutHandler(request: Request, context: some RequestContext) async throws -> HTML {
        guard let (_, path) = markdownTree.findWithPath(path: "Partials/about.md") else {
            throw HTTPError(.notFound)
        }

        let content = try await ContentProvider.file.page(matching: path)
        let data = AboutData(title: "Michael Nisi –\u{00A0}About", post: content.html, description: content.description, wordCount: content.wordCount)

        guard let html = mustacheLibrary.render(data, withTemplate: "article") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }

        return HTML(html: html)
    }
}

private struct AboutData {
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

        ld = """
            {
                "@context": "https://schema.org",
                "@type": "ProfilePage",
                "@id": "https://michaelnisi.com/about#webpage",
                "url": "https://michaelnisi.com/about",
                "inLanguage": "en",
                "name": "\(title)",
                "description": "\(description)",
                "wordCount": \(wordCount),
                "isPartOf": { "@id": "https://michaelnisi.com#website" },
                "mainEntity": { "@id": "https://michaelnisi.com#person" }
            }  
            """
    }
}
