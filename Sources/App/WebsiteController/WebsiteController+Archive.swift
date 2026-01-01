import Foundation
import Hummingbird

extension WebsiteController {
    @Sendable func archiveHandler(request: Request, context: some RequestContext) async throws -> HTML {
        let posts: [ArchiveData.Post] = try await withThrowingTaskGroup(of: ArchiveData.Post.self) { group in
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

                    return ArchiveData.Post(
                        content: content,
                        link: post.path.toDirectoryPath()
                    )
                }
            }

            var acc: [ArchiveData.Post] = []

            for try await result in group {
                acc.append(result)
            }

            return acc.sorted()
        }

        let data = ArchiveData(title: .title("Archive"), posts: posts)

        guard let html = mustacheLibrary.render(data, withTemplate: "archive") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }

        return HTML(html: html)
    }
}

private struct ArchiveData {
    struct Post: Comparable {
        let date: Date
        let title: String
        let url: String
        let link: String
        let description: String
        let wordCount: Int
        let dateString: String
    }

    let title: String
    let posts: [Post]
    let ld: String

    init(title: String, posts: [Post]) {
        self.title = title
        self.posts = posts
        ld = ArchiveLinkedData(name: title).json
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = .init(identifier: "en_US_POSIX")
    formatter.dateStyle = .long

    return formatter
}()

extension ArchiveData.Post {
    init(content: Content, link: String) {
        date = content.date
        title = content.title
        url = content.absoluteURL
        self.link = link
        description = content.description
        wordCount = content.wordCount
        dateString = dateFormatter.string(from: date)
    }

    fileprivate static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.date > rhs.date
    }
}
