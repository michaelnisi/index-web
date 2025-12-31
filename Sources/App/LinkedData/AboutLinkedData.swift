import Foundation

struct AboutLinkedData: LinkedData {
    let context: String
    let type: String
    let id: String
    let url: String
    let inLanguage: String
    let name: String
    let description: String
    let wordCount: Int
    let isPartOf: LinkedDataReference
    let mainEntity: LinkedDataReference

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
        self.context = "https://schema.org"
        self.type = "ProfilePage"
        self.id = "https://michaelnisi.com/about#webpage"
        self.url = "https://michaelnisi.com/about"
        self.inLanguage = "en"
        self.name = name
        self.description = description
        self.wordCount = wordCount
        self.isPartOf = LinkedDataReference(id: "https://michaelnisi.com#website")
        self.mainEntity = LinkedDataReference(id: "https://michaelnisi.com#person")
    }
}
