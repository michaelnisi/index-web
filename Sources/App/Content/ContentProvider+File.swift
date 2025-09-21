import Foundation

extension ContentProvider {
    static let file: ContentProvider = .init(
        dependencies: .init(partial: getPartial)
    )
}

private func getPartial(matching path: String) async throws -> HTMLPartial {
    let file = try PostFile(string: path)
    let markdown = try await file.handle()
    let html = MarkdownHTMLTransformer.html(from: markdown)
    let partial = HTMLPartial(html: html, date: file.date)

    return partial
}

extension String {
    func ISO8601() -> Date? {
        var tokens = Array(self.split(separator: "-").reversed())
        var dateComponents = DateComponents()

        while !tokens.isEmpty {
            if let token = tokens.popLast(), let candidate = Int(token) {
                if dateComponents.year == nil {
                    dateComponents.year = candidate
                }
                if dateComponents.month == nil {
                    dateComponents.month = candidate
                }
                if dateComponents.day == nil {
                    dateComponents.day = candidate
                }
            }
        }

        return Calendar.current.date(from: dateComponents)
    }
}

extension Date {
    init?(ISO8601 string: String) {
        guard let date = string.ISO8601() else {
            return nil
        }

        self = date
    }
}

private struct PostFile {
    enum Failure: Error {
        case noResourcePath
        case notFound
        case encoding
        case invalidPath(String)
    }

    let url: URL
    let date: Date

    init(string: String) throws {
        guard let resourcePath = Bundle.module.resourcePath else {
            throw Failure.noResourcePath
        }

        let path = "\(resourcePath)/\(string)"

        self.url = URL(fileURLWithPath: path)

        guard let date = string.ISO8601() else {
            throw Failure.invalidPath(string)
        }

        self.date = date
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
