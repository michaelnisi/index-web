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
