import Foundation
import System

protocol PostFlow {
    var filePath: FilePath { get }
    func handle() async throws
}

extension PostFlow {
    func handle() async throws {
        print("NYI")
    }
}

struct PostIgnore: PostFlow {
    let filePath: FilePath
}

struct PostDirectory: PostFlow {
    let filePath: FilePath
}

struct PostFile: PostFlow {
    let filePath: FilePath
}

func makePostFlow(string: String) -> any PostFlow {
    let filePath = FilePath(string)

    guard
        let resourcePath = Bundle.module.resourcePath,
        filePath.components.contains("posts")
    else {
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
