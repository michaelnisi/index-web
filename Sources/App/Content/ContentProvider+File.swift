import Foundation

extension ContentProvider {
    static let file: ContentProvider = .init(
        dependencies: .init(posts: loadPosts)
    )
}

private func loadPosts() async throws -> [Post] {
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

        let fs = FileManager()

        fs.changeCurrentDirectoryPath(directory)
        print(fs.fileExists(atPath: filename))

        let d = try Data(contentsOf: url)
        guard let string = String(data: d, encoding: .utf8) else {
            throw Failure.encoding
        }

        self.string = string
    }
}
