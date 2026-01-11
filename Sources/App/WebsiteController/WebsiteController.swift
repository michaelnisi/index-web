import Foundation
import Hummingbird
import Logging
import Mustache

struct WebsiteController {
    let markdownTree: FileNode
    let mustacheLibrary: MustacheLibrary
    let logger: Logger
    let cache: KeyValueStore<String, String>

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

extension WebsiteController {
    func cachedHTML(request: Request) async -> String? {
        if let cached = await cache.get(request.uri.path) {
            logger.debug("cache hit")

            return cached
        }

        return nil
    }

    func cacheHTML(request: Request, html: String) async {
        await cache.set(request.uri.path, value: html)
    }
}

struct HTML: ResponseGenerator {
    let html: String

    public func response(from request: Request, context: some RequestContext) throws -> Response {
        .ifNoneMatch(html: html, request: request)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = .init(identifier: "en_US_POSIX")
    formatter.dateStyle = .long

    return formatter
}()

extension String {
    static func title(_ page: String) -> String {
        "Michael Nisi — \(page)"
    }

    static func canonicalURL(for path: String) -> String {
        let normalized = path.hasPrefix("/") ? path : "/" + path
        return "https://michaelnisi.com" + normalized
    }

    static func date(date: Date) -> String {
        dateFormatter.string(from: date)
    }
}
