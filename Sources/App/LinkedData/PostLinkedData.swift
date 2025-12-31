import Foundation

struct PostLinkedData: LinkedData {
    let context: String = "https://schema.org"
    let type: String = "WebPage"
    let id: String
    let url: String
    let name: String
    let description: String
    let wordCount: Int
    let inLanguage: String = "en"
    let isPartOf: LinkedDataReference
    let mainEntity: LinkedDataReference

    enum CodingKeys: String, CodingKey {
        case context = "@context"
        case type = "@type"
        case id = "@id"
        case url
        case name
        case description
        case wordCount
        case inLanguage
        case isPartOf
        case mainEntity
    }

    init(absoluteURL: String, title: String, description: String, wordCount: Int) {
        self.id = "\(absoluteURL)#webpage"
        self.url = absoluteURL
        self.name = "Michael Nisi –\u{00A0}\(title)"
        self.description = description
        self.wordCount = wordCount
        self.isPartOf = LinkedDataReference(id: "https://michaelnisi.com#website")
        self.mainEntity = LinkedDataReference(id: "https://michaelnisi.com#person")
    }
}
