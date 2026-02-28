import Foundation
import Hummingbird
import Logging

struct SitemapController {
    let markdownTree: FileNode
    let logger: Logger

    func addRoutes(to router: Router<some RequestContext>) {
        router.get("/sitemap.xml", use: sitemapHandler)
    }
}

extension SitemapController {
    @Sendable func sitemapHandler(
        request: Request,
        context: some RequestContext
    ) async throws -> SitemapResponse {
        let posts = try await loadAllPostsSortedByDate()
        let xml = buildSitemapXML(posts: posts)

        return SitemapResponse(xml: xml)
    }
}

extension SitemapController {
    private func loadAllPostsSortedByDate() async throws -> [SitemapPost] {
        try await withThrowingTaskGroup(of: SitemapPost.self) { group in
            guard
                let posts = markdownTree.allNodes(matching: "posts")
                    .first?.node.allFiles()
            else {
                return []
            }

            for post in posts {
                group.addTask {
                    let content = try await ContentProvider.file
                        .post(matching: post.path.inPartialsDirectory)

                    return SitemapPost(content: content, path: post.path)
                }
            }

            var accumulator: [SitemapPost] = []

            for try await result in group {
                accumulator.append(result)
            }

            return accumulator.sorted { $0.date > $1.date }
        }
    }

    private func buildSitemapXML(posts: [SitemapPost]) -> String {
        var xml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
            """

        // Static pages
        let staticPages: [(loc: String, changefreq: String, priority: String)] = [
            ("https://michaelnisi.com/", "weekly", "1.0"),
            ("https://michaelnisi.com/archive", "weekly", "0.7"),
            ("https://michaelnisi.com/about", "monthly", "0.5"),
            ("https://michaelnisi.com/now", "monthly", "0.5"),
        ]

        for page in staticPages {
            xml += """

                <url>
                <loc>\(page.loc)</loc>
                <changefreq>\(page.changefreq)</changefreq>
                <priority>\(page.priority)</priority>
                </url>
                """
        }

        // Blog posts
        for post in posts {
            xml += """

                <url>
                <loc>\(post.url)</loc>
                <lastmod>\(post.lastmod)</lastmod>
                <changefreq>monthly</changefreq>
                <priority>0.8</priority>
                </url>
                """
        }

        xml += """

            </urlset>
            """

        return xml
    }
}

// MARK: - Response

struct SitemapResponse: ResponseGenerator {
    let xml: String

    func response(from request: Request, context: some RequestContext) throws -> Response {
        .ifNoneMatch(
            body: xml,
            contentType: "application/xml; charset=utf-8",
            request: request
        )
    }
}

// MARK: - Sitemap Post

private struct SitemapPost {
    let date: Date
    let url: String
    let lastmod: String

    init(content: Content, path: String) {
        date = content.date
        url = .canonicalURL(for: path.toDirectoryPath())
        lastmod = Self.dateFormatter.string(from: content.date)
    }

    private nonisolated(unsafe) static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        return formatter
    }()
}
