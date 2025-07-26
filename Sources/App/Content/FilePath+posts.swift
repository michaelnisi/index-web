import Foundation
import System

protocol PostHandler {
    var filePath: FilePath { get }
    func handle() async throws -> String
}

extension PostHandler {
    func handle() async throws -> String {
        "No-op: conditions not met."
    }
}

struct PostIgnore: PostHandler {
    let filePath: FilePath
}

struct PostDirectory: PostHandler {
    let filePath: FilePath
}

struct PostFile: PostHandler {
    enum Failure: Error {
        case notFound
        case encoding
    }

    let filePath: FilePath

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

struct PostIdentifier: Identifiable {
    enum Category {
        case all, year, month, single
    }

    let id: String
    let category: Category

    init?(string: String) {
        guard
            string.isPostsPath,
            let dashed = string.splittingPostsPath?.dashed
        else {
            return nil
        }

        self.id = dashed
        self.category = .single
    }
}

extension String {
    var isPostsPath: Bool {
        contains("/posts")
    }

    var splittingPostsPath: String? {
        guard let last = split(separator: "/posts/").last else {
            return nil
        }

        return String(last)
    }

    var dashed: String {
        replacingOccurrences(of: "/", with: "-")
    }

    var appendingMarkdownExtension: String {
        "\(self).md"
    }
}

// TODO: Replace
func makePostFlow(string: String) -> any PostHandler {
    let filePath = FilePath(string)

    guard let resourcePath = Bundle.module.resourcePath, string.isPostsPath else {
        return PostIgnore(filePath: filePath)
    }

    guard filePath.lastComponent != "posts" else {
        return PostIgnore(filePath: filePath)
    }

    let tmp = filePath.string
    guard let withoutPosts = tmp.split(separator: "/posts/").first else {
        return PostIgnore(filePath: filePath)
    }

    let dashed = withoutPosts.replacingOccurrences(of: "/", with: "-")

    let path: String
    if let last = filePath.lastComponent?.string, Int(last) == nil {
        path = "\(resourcePath)/Partials/posts/\(dashed).md"
        return PostFile(filePath: .init(path))
    } else {
        path = "\(resourcePath)/Partials/posts/\(dashed)"

        return PostDirectory(filePath: .init(path))
    }
}



