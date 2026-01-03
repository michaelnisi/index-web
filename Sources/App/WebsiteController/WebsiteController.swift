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
        .ifNoneMatch(html: html, request: request)
    }
}

extension String {
    static func title(_ page: String) -> String {
        "Michael Nisi — \(page)"
    }
}
