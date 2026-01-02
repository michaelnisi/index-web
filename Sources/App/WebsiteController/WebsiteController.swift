import Foundation
import Hummingbird
import Logging
import Mustache

struct WebsiteController {
    let markdownTree: FileNode
    let mustacheLibrary: MustacheLibrary
    let logger: Logger

    func addRoutes(to router: Router<some RequestContext>) {
        router.get("/", use: indexHandler)
        router.get("/posts/**", use: postHandler)
        router.get("/now", use: nowHandler)
        router.get("/about", use: aboutHandler)
        router.get("/archive", use: archiveHandler)

        router.head("/", use: indexHandler)
        router.head("/posts/**", use: postHandler)
        router.head("/now", use: nowHandler)
        router.head("/about", use: aboutHandler)
        router.head("/archive", use: archiveHandler)
    }
}

struct HTML: ResponseGenerator {
    let html: String

    public func response(from request: Request, context: some RequestContext) throws -> Response {
        request.method == .head ? .head() : .get(html: html)
    }
}

extension String {
    static func title(_ page: String) -> String {
        "Michael Nisi — \(page)"
    }
}

extension Response {
    fileprivate static let headers: HTTPFields = [
        .contentType: "text/html; charset=utf-8",
        .cacheControl: "public, max-age=86400, stale-while-revalidate=604800, stale-if-error=604800",
        .connection: "keep-alive",
    ]
    
    fileprivate static func head() -> Response {
        .init(status: .ok, headers: headers)
    }
    
    fileprivate static func get(html: String) -> Response {
        .init(status: .ok, headers: headers, body: .init(byteBuffer: ByteBuffer(string: html)))
    }
}
