import Foundation

struct AboutLinkedData: LinkedData {
    let context = "https://schema.org"
    let type = "ProfilePage"
    let id = "https://michaelnisi.com/about#webpage"
    let url = "https://michaelnisi.com/about"
    let inLanguage = "en"
    let name: String
    let description: String
    let wordCount: Int
    let isPartOf = LinkedDataReference(id: "https://michaelnisi.com#website")
    let mainEntity = LinkedDataReference(id: "https://michaelnisi.com#person")

    private enum CodingKeys: String, CodingKey {
        case context = "@context"
        case type = "@type"
        case id = "@id"
        case url
        case inLanguage
        case name
        case description
        case wordCount
        case isPartOf
        case mainEntity
    }

    init(name: String, description: String, wordCount: Int) {
        self.name = name
        self.description = description
        self.wordCount = wordCount
    }
}
