import Foundation

extension String {
    /// Convert `posts/2025/08/21/nuts` → `posts/2025-08-21-nuts.md`
    func toFilename() -> String {
        guard isValidDirectoryPath() else { return self }
        let parts = self.split(separator: "/")
        let prefix = parts.dropLast(4).joined(separator: "/")
        let year = parts[parts.count - 4]
        let month = parts[parts.count - 3]
        let day = parts[parts.count - 2]
        let slug = parts.last!
        return "\(prefix)/\(year)-\(month)-\(day)-\(slug).md"
    }

    /// Convert `posts/2025-08-21-nuts.md` → `posts/2025/08/21/nuts`
    func toDirectoryPath() -> String {
        guard isValidFilename() else { return self }
        let parts = self.split(separator: "/")
        let prefix = parts.dropLast().joined(separator: "/")
        let name = parts.last!.dropLast(3)  // remove .md
        let comps = name.split(separator: "-", maxSplits: 3)
        let year = comps[0]
        let month = comps[1]
        let day = comps[2]
        let slug = comps[3]
        return "\(prefix)/\(year)/\(month)/\(day)/\(slug)"
    }

    /// Validate format: posts/YYYY/MM/DD/slug
    func isValidDirectoryPath() -> Bool {
        self.wholeMatch(of: #/^.+/\d{4}/\d{2}/\d{2}/[a-z0-9-]+$/#) != nil
    }

    /// Validate format: posts/YYYY-MM-DD-slug.md
    func isValidFilename() -> Bool {
        self.wholeMatch(of: #/^.+/\d{4}-\d{2}-\d{2}-[a-z0-9-]+\.md$/#) != nil
    }
}
