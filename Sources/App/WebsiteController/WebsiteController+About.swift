import Foundation
import Hummingbird

extension WebsiteController {
    @Sendable func aboutHandler(request: Request, context: some RequestContext) async throws -> HTML {
        guard let (_, path) = markdownTree.findWithPath(path: "Partials/about.md") else {
            throw HTTPError(.notFound)
        }

        let content = try await ContentProvider.file.page(matching: path)
        let data = AboutData(title: "Michael Nisi – About", post: content.html)

        guard let html = mustacheLibrary.render(data, withTemplate: "article") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }

        return HTML(html: html)
    }
}

private struct AboutData {
    let title: String
    let post: String
    let ld: String
    
    init(title: String, post: String) {
        self.title = title
        self.post = post
        
        ld = """
        {
            "@context": "https://schema.org",
            "@type": "WebPage",
            "@id": "https://michaelnisi.com/about#webpage",
            "url": "https://michaelnisi.com/about",
            "name": "\(title)",
            "isPartOf": { "@id": "https://michaelnisi.com#website" },
            "mainEntity": { "@id": "https://michaelnisi.com#person" }
        }  
        """
    }
}
