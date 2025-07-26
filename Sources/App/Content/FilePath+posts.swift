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

struct PostFile: PostHandler {
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
