import Foundation
import Hummingbird

extension WebsiteController {
    @Sendable func indexHandler(request: Request, context: some RequestContext) async throws -> HTML {
        let posts: [IndexData.Post] = try await withThrowingTaskGroup(of: IndexData.Post.self) { group in
            guard
                let posts = markdownTree.allNodes(matching: "posts")
                    .first?.node.allFiles()
            else {
                return []
            }

            for post in posts {
                group.addTask {
                    let content = try await ContentProvider.file
                        .post(matching: .partialsPath(post.path))

                    return IndexData.Post(
                        content: content,
                        link: post.path.toDirectoryPath()
                    )
                }
            }

            var acc: [IndexData.Post] = []

            for try await result in group {
                acc.append(result)
            }

            return acc.sorted()
        }

        let data = IndexData(title: "Michael Nisi — Software Engineer", posts: posts)

        guard let html = mustacheLibrary.render(data, withTemplate: "index") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }

        return HTML(html: html)
    }
}

private struct IndexData {
    struct Post: Comparable {
        let content: String
        let date: Date
        let title: String
        let url: String
        let link: String
    }

    let title: String
    let posts: [Post]
    let ld: String

    init(title: String, posts: [Post]) {
        self.title = title
        self.posts = posts

        ld = """
            {
               "@context": "https://schema.org",
               "@graph": [
                 {
                   "@type": "WebSite",
                   "@id": "https://michaelnisi.com#website",
                   "url": "https://michaelnisi.com",
                   "name": "Michael Nisi",
                   "inLanguage": "en"
                 },
                 {
                   "@type": "WebPage",
                   "@id": "https://michaelnisi.com#webpage",
                   "url": "https://michaelnisi.com",
                   "name": "\(title)",
                   "isPartOf": { "@id": "https://michaelnisi.com#website" },
                   "primaryImageOfPage": {
                     "@type": "ImageObject",
                     "url": "https://res.cloudinary.com/duiiv2f8o/image/upload/v1762078766/IMG_0126_xws0m4.jpg"
                   }
                 },
                 {
                   "@type": "Person",
                   "@id": "https://michaelnisi.com#person",
                   "name": "Michael Nisi",
                   "url": "https://michaelnisi.com",
                   "image": "https://res.cloudinary.com/duiiv2f8o/image/upload/v1762078766/IMG_0126_xws0m4.jpg",
                   "description": "Michael Nisi is a seasoned Apple-platform software engineer, Swift maximalist, type-driven design enthusiast, and full-time romantic about the personal web — currently balancing strict Swift 6 concurrency, Solarized color systems, Swiss-grid typography, and single-fin longboard sessions between Cantabria, Thy, and the rest of Europe.",
                   "jobTitle": "Software Engineer",
                   "worksFor": {
                     "@type": "Organization",
                     "name": "apploft."
                   },
                   "sameAs": [
                     "https://linktr.ee/michaelnisi",
                     "https://github.com/michaelnisi",
                     "https://www.instagram.com/podustle/",
                     "https://michaelnisi.substack.com/"
                   ],
                   "knowsAbout": ["Apple", "iOS", "Swift", "Literature", "Music", "Surfing"]
                 }
               ]
            }
            """
    }
}

extension IndexData.Post {
    init(content: Content, link: String) {
        self.content = content.html
        date = content.date
        title = content.title
        url = content.absoluteURL
        self.link = link
    }

    fileprivate static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.date > rhs.date
    }
}
