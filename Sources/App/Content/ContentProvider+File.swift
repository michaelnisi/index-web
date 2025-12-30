import Foundation

extension ContentProvider {
    static let file: ContentProvider = .init(
        dependencies: .init(
            post: getPostPartial,
            page: getPagePartial
        )
    )
}

private func getPagePartial(matching path: String) async throws -> Content {
    let file = try PageFile(string: path)
    let markdown = try await file.handle()
    let absoluteURL: String = .init(urlString: path)
    let date: Date = .distantPast  // TODO: Why this difference?

    return MarkdownHTMLTransformer.content(from: markdown, absoluteURL: absoluteURL, date: date)
}

private func getPostPartial(matching path: String) async throws -> Content {
    let file = try PostFile(string: path)
    let markdown = try await file.handle()
    let absoluteURL: String = .init(urlString: path)
    let date = file.date

    return MarkdownHTMLTransformer.content(from: markdown, absoluteURL: absoluteURL, date: date)
}

private struct PageFile {
    enum Failure: Error {
        case noResourcePath
        case notFound
        case encoding
        case invalidPath(String)
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

        guard let date = url.leadingISO8601DateFromFilename() else {
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

extension URL {
    /// Parses a leading `YYYY-MM-DD-` from the last path component and returns a Date (midnight UTC).
    ///
    /// ```swift
    /// "Partials/posts/2025-06-06-troubled.md" -> 2025-06-06 00:00:00 +0000
    /// "2025-06-06-foo.md" -> valid
    /// "foo-2025-06-06.md" -> nil (date not at start)
    /// "2025-13-01-foo.md" -> nil (invalid month)
    func leadingISO8601DateFromFilename() -> Date? {
        let last = lastPathComponent
        let pattern = #"^(\d{4})-(\d{2})-(\d{2})-"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
            let m = regex.firstMatch(in: last, range: NSRange(last.startIndex..., in: last)),
            let yRange = Range(m.range(at: 1), in: last),
            let mRange = Range(m.range(at: 2), in: last),
            let dRange = Range(m.range(at: 3), in: last),
            let year = Int(last[yRange]),
            let month = Int(last[mRange]),
            let day = Int(last[dRange]),
            (1...12).contains(month),
            (1...31).contains(day)
        else {
            return nil
        }

        var comps = DateComponents()
        comps.calendar = Calendar(identifier: .iso8601)
        comps.timeZone = TimeZone(secondsFromGMT: 0)  // midnight UTC
        comps.year = year
        comps.month = month
        comps.day = day

        return comps.calendar?.date(from: comps)
    }
}
