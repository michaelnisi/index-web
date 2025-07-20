import Foundation

extension ContentProvider {
    static let file: ContentProvider = .init(
        dependencies: .init(posts: getPosts)
    )
}

private func getPosts() async throws -> [Post] {
    let hello = try File(filename: "hello.md")
    let post = try await loadFile(hello)

    return [post]
}

private func loadFile(_ file: File) async throws -> Post {
    let html = MarkdownHTMLTransformer.html(from: file.string)

    return .init(date: .now, html: html, category: .swiftserver)
}

struct File {
    enum Failure: Error {
        case notFound
        case encoding
    }

    let string: String

    init(filename: String) throws {
        guard
            let directory = Bundle.module.resourcePath,
            let url = URL(filePath: .init("\(directory)/\(filename)"))
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
