import Foundation

struct SlugComponents {
    let year: Int
    let month: Int
    let slug: String
}

extension String {
    func slugComponents() -> SlugComponents? {
        let path = self.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        let components = path.split(separator: "/")
        guard components.count == 4, components[0] == "posts" else {
            return nil
        }

        guard
            let year = Int(components[1]), components[1].count == 4,
            let month = Int(components[2]), (1...12).contains(month)
        else {
            return nil
        }

        let slug = String(components[3].split(separator: ".").first ?? "")
        return SlugComponents(year: year, month: month, slug: slug)
    }
}

extension String {
    func markdownPath() -> String {
        let path = self.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        // Root or index
        if path.isEmpty || path == "index" || path.hasPrefix("index.") {
            return "index.md"
        }

        // If already ends in .md, return as-is
        if path.hasSuffix(".md") {
            return path
        }

        // Try extracting slug components
        if let slug = self.slugComponents() {
            let month = String(format: "%02d", slug.month)
            return "posts/\(slug.year)-\(month)-\(slug.slug).md"
        }

        // Fallback: strip .html/.htm and add .md
        var base = path
        if path.hasSuffix(".html") || path.hasSuffix(".htm"),
            let dotIndex = path.lastIndex(of: ".")
        {
            base = String(path[..<dotIndex])
        }

        return base + ".md"
    }
}

extension SlugComponents {
    func markdownPath() -> String {
        let month = String(format: "%02d", month)
        return "posts/\(year)-\(month)-\(slug).md"
    }
}
