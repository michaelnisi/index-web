import Foundation

struct Content {
    let html: String
    let date: Date
    let title: String
    let absoluteURL: String
}

extension String {
    /// Creates absolute URL String from potential `urlString`.
    init(urlString: String) {
        var components = URLComponents(string: urlString) ?? URLComponents()
        if components.host == nil && components.path.isEmpty {
            components.path = urlString
        }
        components.scheme = "https"
        components.host = "michaelnisi.com"
        if !components.path.hasPrefix("/") {
            components.path = "/" + components.path
        }
        self = components.url?.absoluteString ?? "https://michaelnisi.com" + components.path
    }
}
