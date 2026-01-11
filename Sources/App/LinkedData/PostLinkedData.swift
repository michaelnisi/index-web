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
    let isPartOf = LinkedDataReference(id: "https://michaelnisi.com#website")
    let mainEntity = LinkedDataReference(id: "https://michaelnisi.com#person")

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

    init(canonical: String, name: String, description: String, wordCount: Int) {
        self.id = "\(canonical)#webpage"
        self.url = canonical
        self.name = name
        self.description = description
        self.wordCount = wordCount
    }
}
