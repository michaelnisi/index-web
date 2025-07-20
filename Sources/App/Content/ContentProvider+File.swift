import Foundation
import System

extension ContentProvider {
    static let file: ContentProvider = .init(
        dependencies: .init(partial: getPartial)
    )
}

private func getPartial(matching path: String) async throws -> HTMLPartial {
    let markdownFile = try MarkdownFile(path: path)
    let post = try await htmlPartial(markdownFile)

    return post
}

private func htmlPartial(_ file: MarkdownFile) async throws -> HTMLPartial {
    let html = MarkdownHTMLTransformer.html(from: file.string)

    return .init(date: .now, html: html, category: .swiftserver)
}

struct MarkdownFile {
    enum Failure: Error {
        case notFound
        case encoding
    }

    let string: String

    init(path: String) throws {
        guard
            let filePath = path.filePath,
            let url = URL(filePath: filePath, directoryHint: .notDirectory)
        else {
            throw Failure.notFound
        }

        let data = try Data(contentsOf: url)
        guard let string = String(data: data, encoding: .utf8) else {
            throw Failure.encoding
        }

        self.string = string
    }
}

extension String {
    fileprivate var filePath: FilePath? {
        guard let resourcePath = Bundle.module.resourcePath else {
            return nil
        }

        guard let withoutPosts = self.split(separator: "/posts/").first else {
            return nil
        }

        let path = "\(resourcePath)/Partials/posts/\(withoutPosts.replacingOccurrences(of: "/", with: "-")).md"
        let filePath = FilePath(path)

        return filePath
    }
}
