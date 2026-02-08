import Foundation
import Hummingbird
import Logging

struct RSSFeedController {
    let markdownTree: FileNode
    let logger: Logger

    func addRoutes(to router: Router<some RequestContext>) {
        router.get("/feed", use: feedHandler)
    }
}

extension RSSFeedController {
    @Sendable func feedHandler(
        request: Request,
        context: some RequestContext
    ) async throws -> RSSFeedResponse {
        let posts = try await loadAllPostsSortedByDate()
        let xml = buildRSSXML(posts: posts)

        return RSSFeedResponse(xml: xml)
    }
}

extension RSSFeedController {
    private func loadAllPostsSortedByDate() async throws -> [FeedPost] {
        try await withThrowingTaskGroup(of: FeedPost.self) { group in
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

                    return FeedPost(content: content, path: post.path)
                }
            }

            var accumulator: [FeedPost] = []

            for try await result in group {
                accumulator.append(result)
            }

            return accumulator.sorted { $0.date > $1.date }
        }
    }

    private func buildRSSXML(posts: [FeedPost]) -> String {
        var xml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:content="http://purl.org/rss/1.0/modules/content/">
            <channel>
            <title>Michael Nisi</title>
            <link>https://michaelnisi.com</link>
            <description>Strong types and single fins.</description>
            <language>en-us</language>
            <atom:link href="https://michaelnisi.com/feed" rel="self" type="application/rss+xml"/>
            <image>
            <url>https://michaelnisi.com/favicon.ico</url>
            <title>Michael Nisi</title>
            <link>https://michaelnisi.com</link>
            </image>
            """

        for post in posts {
            let pubDate = Self.rfc822Formatter.string(from: post.date)

            xml += """

                <item>
                <title>\(post.title.xmlEscaped)</title>
                <link>\(post.url)</link>
                <guid isPermaLink="true">\(post.url)</guid>
                <pubDate>\(pubDate)</pubDate>
                <description>\(post.description.xmlEscaped)</description>
                <content:encoded><![CDATA[\(post.html)]]></content:encoded>
                </item>
                """
        }

        xml += """

            </channel>
            </rss>
            """

        return xml
    }

    private static let rfc822Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        return formatter
    }()
}

// MARK: - Response

struct RSSFeedResponse: ResponseGenerator {
    let xml: String

    func response(from request: Request, context: some RequestContext) throws -> Response {
        .ifNoneMatch(
            body: xml,
            contentType: "application/rss+xml; charset=utf-8",
            request: request
        )
    }
}

// MARK: - Feed Post

private struct FeedPost {
    let title: String
    let date: Date
    let html: String
    let description: String
    let url: String

    init(content: Content, path: String) {
        title = content.title
        date = content.date
        html = content.html.strippingLeadingH1()
        description = content.description
        url = .canonicalURL(for: path.toDirectoryPath())
    }
}

// MARK: - XML Escaping

extension String {
    fileprivate var xmlEscaped: String {
        replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
