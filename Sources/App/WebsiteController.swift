import Foundation
import Hummingbird
import Mustache

struct WebsiteController {
    let mustacheLibrary: MustacheLibrary

    func addRoutes(to router: Router<some RequestContext>) {
        router.get("/", use: postHandler)
        router.get("/posts/*/**", use: postHandler)
    }

    // TODO: Implement one handler per mustache template

    @Sendable func postHandler(request: Request, context: some RequestContext) async throws -> HTML {
        let html = try await ContentProvider.file.partial(matching: request.uri.path).html
        let data = ["post": html]

        print(request.uri.path)
        print(request.uri.queryParameters)

        guard let html = mustacheLibrary.render(data, withTemplate: "index") else {
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
