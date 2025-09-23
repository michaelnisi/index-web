import Foundation

struct SlugComponents: Equatable {
    let year: Int
    let month: Int
    let day: Int
    let slug: String
}

extension SlugComponents {
    init?(string: String) {
        guard let me = string.slugComponents() else {
            return nil
        }

        self = me
    }
}

extension String {
    func slugComponents() -> SlugComponents? {
        let path = self.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        let components = path.split(separator: "/")
        guard components.count == 5, components[0] == "posts" else {
            return nil
        }

        guard
            let year = Int(components[1]), components[1].count == 4,
            let month = Int(components[2]), (1...12).contains(month),
            let day = Int(components[3]), (1...31).contains(day)
        else {
            return nil
        }

        let slug = String(components[4].split(separator: ".").first ?? "")

        return SlugComponents(year: year, month: month, day: day, slug: slug)
    }
}

extension String {
    func markdownPath() -> String {
        let path = self.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        if path.isEmpty || path == "index" || path.hasPrefix("index.") {
            return "index.md"
        }

        if path.hasSuffix(".md") {
            return path
        }

        if let slug = self.slugComponents() {
            let month = String(format: "%02d", slug.month)
            let day = String(format: "%02d", slug.day)

            return "posts/\(slug.year)-\(month)-\(day)-\(slug.slug).md"
        }

        var base = path
        if path.hasSuffix(".html") || path.hasSuffix(".htm"),
            let dotIndex = path.lastIndex(of: ".")
        {
            base = String(path[..<dotIndex])
        }

        return base + ".md"
    }
}
