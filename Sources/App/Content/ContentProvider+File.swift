import Foundation

extension ContentProvider {
    static let file: ContentProvider = .init(
        dependencies: .init(partial: getPartial)
    )
}

private func getPartial(matching path: String) async throws -> HTMLPartial {
    let markdown = try await PostFile(string: path).handle()
    let html = MarkdownHTMLTransformer.html(from: markdown)
    let partial = HTMLPartial(date: .now, html: html, category: .swiftserver)

    return partial
}

private struct PostFile {
    enum Failure: Error {
        case noResourcePath
        case notFound
        case encoding
    }
    
    let url: URL

    init(string: String) throws {
        guard let resourcePath = Bundle.module.resourcePath else {
            throw Failure.noResourcePath
        }

        let path = "\(resourcePath)/\(string)"

        self.url = URL(fileURLWithPath: path)
    }

    func handle() async throws -> String {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw Failure.notFound
         }

        let data = try Data(contentsOf: url)
        guard let string = String(data: data, encoding: .utf8) else {
            throw Failure.encoding
        }

        return string
    }
}

func buildFileTree(at url: URL) throws -> FileNode {
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
        throw PostFile.Failure.notFound
    }

    if isDirectory.boolValue {
        let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        let children = try contents.map { try buildFileTree(at: $0) }
        return .directory(name: url.lastPathComponent, children: children)
    } else {
        return .file(name: url.lastPathComponent)
    }
}
