import Foundation

extension String {
    func markdownPath() -> String {
        // Remove leading slash
        var path = trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        // Handle root or index
        if path.isEmpty || path == "index" || path.hasPrefix("index.") {
            return "index.md"
        }
        
        // Strip .html or .htm extension
        if path.hasSuffix(".html") || path.hasSuffix(".htm") {
            if let dotIndex = path.lastIndex(of: ".") {
                path = String(path[..<dotIndex])
            }
        }
        
        // Match /posts/<year>/<month>/<slug>
        let components = path.split(separator: "/")
        if components.count == 4, components[0] == "posts" {
            let year = components[1]
            let rawMonth = components[2]
            let slug = components[3]
            
            // Validate year = exactly 4 digits
            let yearString = String(year)
            let isValidYear = yearString.count == 4 && yearString.allSatisfy(\.isNumber)
            
            // Normalize and validate month
            if isValidYear, let monthInt = Int(rawMonth), (1...12).contains(monthInt) {
                let month = String(format: "%02d", monthInt)
                return "posts/\(yearString)-\(month)-\(slug).md"
            }
        }
        
        // Default fallback
        if !path.hasSuffix(".md") {
            path += ".md"
        }
        
        return path
    }
}
