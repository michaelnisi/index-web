import Foundation
import System

extension ContentProvider {
    static let file: ContentProvider = .init(
        dependencies: .init(partial: getPartial)
    )
}

private func getPartial(matching path: String) async throws -> HTMLPartial {
    let markdown = try MarkdownFile(path: path)
    let html = MarkdownHTMLTransformer.html(from: markdown.string)
    let partial = HTMLPartial(date: .now, html: html, category: .swiftserver)

    return partial
}

struct MarkdownFile {
    enum Failure: Error {
        case notFound
        case encoding
    }

    let string: String

    init(path: String) throws {
        guard
            let postFlow = makePostFlow(string: path) as? PostFile,
            let url = URL(filePath: postFlow.filePath, directoryHint: .notDirectory)
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
