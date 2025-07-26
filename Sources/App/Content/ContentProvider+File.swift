import Foundation
import System

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

private protocol PostHandler {
    var filePath: FilePath { get }
    func handle() async throws -> String
}

extension PostHandler {
    func handle() async throws -> String {
        "No-op: conditions not met."
    }
}

private struct PostFile: PostHandler {
    enum Failure: Error {
        case notFound
        case encoding
    }

    let filePath: FilePath

    init(string: String) {
        guard let resourcePath = Bundle.module.resourcePath else {
            fatalError("***")
        }

        let path = "\(resourcePath)/\(string)"

        self.filePath = FilePath(path)
    }

    func handle() async throws -> String {
        guard let url = URL(filePath: filePath, directoryHint: .notDirectory) else {
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
        throw NSError(domain: "FileNodeError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Path does not exist"])
    }

    if isDirectory.boolValue {
        let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        let children = try contents.map { try buildFileTree(at: $0) }
        return .directory(name: url.lastPathComponent, children: children)
    } else {
        return .file(name: url.lastPathComponent)
    }
}

func printFileTree(at filePath: FilePath) {
    guard let url = URL(filePath: filePath) else {
        print("no URL")
        return
    }

    do {
        let tree = try buildFileTree(at: url)
        print(tree)
    } catch {
        print(error)
    }
}
