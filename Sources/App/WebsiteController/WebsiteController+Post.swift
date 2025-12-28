import Foundation
import Hummingbird

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension WebsiteController {
    @Sendable func postHandler(request: Request, context: some RequestContext) async throws -> HTML {
        guard let (_, path) = markdownTree.findWithPath(path: .partialsPath(request.uri.path.markdownPath())) else {
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
    let post: String
    let ld: String

    init(content: HTMLPartial) {
        self.post = content.html
        self.ld = """
            {
              "@context": "https://schema.org",
              "@type": "WebPage",
              "@id": "\(content.absoluteURL)#webpage",
              "url": "\(content.absoluteURL)",
              "name": "\(content.title) | Michael Nisi",
              "isPartOf": "https://michaelnisi.com#website",
              "mainEntity": {
                "@type": "Person",
                "@id": "https://michaelnisi.com#person"
              }
            }    
            """
    }
}

extension String {
    static func partialsPath(_ path: String) -> String {
        "Partials/\(path)"
    }
}

extension String {
    init(urlString: String) {
        var components = URLComponents(string: urlString) ?? URLComponents()
        if components.host == nil && components.path.isEmpty {
            components.path = urlString
        }
        components.scheme = "https"
        components.host = "michaelnisi.com"
        if !components.path.hasPrefix("/") {
            components.path = "/" + components.path
        }
        self = components.url?.absoluteString ?? "https://michaelnisi.com" + components.path
    }
}
