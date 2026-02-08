import Foundation
import Hummingbird
import Logging

struct JSONFeedController {
    let markdownTree: FileNode
    let logger: Logger

    func addRoutes(to router: Router<some RequestContext>) {
        router.get("/feed.json", use: feedHandler)
    }
}

extension JSONFeedController {
    @Sendable func feedHandler(
        request: Request,
        context: some RequestContext
    ) async throws -> JSONFeedResponse {
        let posts = try await loadAllPostsSortedByDate()
        let json = encodeFeed(posts: posts)

        return JSONFeedResponse(json: json)
    }
}

extension JSONFeedController {
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

    private func encodeFeed(posts: [FeedPost]) -> String {
        let items = posts.map { post in
            JSONFeedItem(
                id: post.url,
                url: post.url,
                title: post.title,
                content_html: post.html,
                summary: post.description,
                date_published: Self.rfc3339Formatter.string(from: post.date)
            )
        }

        let feed = JSONFeed(items: items)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        do {
            let data = try encoder.encode(feed)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            logger.error("Failed to encode JSON feed: \(error)")
            return "{}"
        }
    }

    private nonisolated(unsafe) static let rfc3339Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        return formatter
    }()
}

// MARK: - Response

struct JSONFeedResponse: ResponseGenerator {
    let json: String

    func response(from request: Request, context: some RequestContext) throws -> Response {
        .ifNoneMatch(
            body: json,
            contentType: "application/feed+json; charset=utf-8",
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

// MARK: - JSON Feed 1.1

private struct JSONFeed: Encodable {
    let version = "https://jsonfeed.org/version/1.1"
    let title = "Michael Nisi"
    let home_page_url = "https://michaelnisi.com"
    let feed_url = "https://michaelnisi.com/feed.json"
    let favicon = "https://michaelnisi.com/favicon.ico"
    let description = "Strong types and single fins."
    let language = "en-US"
    let authors = [JSONFeedAuthor(name: "Michael Nisi", url: "https://michaelnisi.com/about")]
    let items: [JSONFeedItem]
}

private struct JSONFeedAuthor: Encodable {
    let name: String
    let url: String
}

private struct JSONFeedItem: Encodable {
    let id: String
    let url: String
    let title: String
    let content_html: String
    let summary: String
    let date_published: String
}
