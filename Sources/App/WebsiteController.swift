import Foundation
import Hummingbird
import Mustache

struct WebsiteController {
    let markdownTree: FileNode
    let mustacheLibrary: MustacheLibrary

    func addRoutes(to router: Router<some RequestContext>) {
        router.get("/", use: indexHandler)
        router.get("/posts/**", use: postHandler)
    }

    @Sendable func indexHandler(request: Request, context: some RequestContext) async throws -> HTML {
        guard let html = mustacheLibrary.render((), withTemplate: "index") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }

        return HTML(html: html)
    }

    @Sendable func postHandler(request: Request, context: some RequestContext) async throws -> HTML {
        let md = "Partials/\(request.uri.path.markdownPath())"

        guard let (_, path) = markdownTree.findWithPath(path: md) else {
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

struct HTML: ResponseGenerator {
    let html: String

    public func response(from request: Request, context: some RequestContext) throws -> Response {
        let buffer = ByteBuffer(string: self.html)

        return .init(status: .ok, headers: [.contentType: "text/html"], body: .init(byteBuffer: buffer))
    }
}
