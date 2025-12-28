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
    let ld = """
        {
          "@context": "https://schema.org",
          "@type": "WebPage",
          "@id": "https://michaelnisi.com/about#webpage",
          "url": "https://michaelnisi.com/about",
          "name": "About — Michael Nisi",
          "isPartOf": "https://michaelnisi.com#website",
          "mainEntity": {
            "@type": "Person",
            "@id": "https://michaelnisi.com#person",
            "name": "Michael Nisi",
            "url": "https://michaelnisi.com",
            "image": "https://res.cloudinary.com/duiiv2f8o/image/upload/v1762078766/IMG_0126_xws0m4.jpg",
            "sameAs": [
              "https://linktr.ee/michaelnisi",
              "https://github.com/michaelnisi",
              "https://www.instagram.com/podustle",
              "https://michaelnisi.substack.com"
            ]
          }
        }    
        """
}
